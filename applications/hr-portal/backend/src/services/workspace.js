const k8s = require('@kubernetes/client-node');
const { v4: uuidv4 } = require('uuid');
const dynamodbService = require('./dynamodb');
const ssmService = require('./ssm');
const emailService = require('./email');
const logger = require('../utils/logger');

const kc = new k8s.KubeConfig();
kc.loadFromCluster(); // Load in-cluster config when running in K8s

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
const k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);
const k8sNetworkingApi = kc.makeApiClient(k8s.NetworkingV1Api);

const WORKSPACE_NAMESPACE = 'workspaces';
const ECR_REGISTRY = process.env.ECR_REGISTRY || '920120424621.dkr.ecr.eu-west-1.amazonaws.com';

/**
 * Sanitize name for Kubernetes resource naming
 * Must match: [a-z0-9]([-a-z0-9]*[a-z0-9])?
 */
function sanitizeK8sName(name) {
  return name
    .toLowerCase()
    .normalize('NFD') // Decompose accented characters
    .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
    .replace(/[^a-z0-9-]/g, '-') // Replace invalid chars with hyphen
    .replace(/^-+|-+$/g, '') // Remove leading/trailing hyphens
    .replace(/-+/g, '-') // Collapse multiple hyphens
    .substring(0, 63); // K8s limit is 63 chars
}

/**
 * Provision a new workspace for an employee
 */
async function provisionWorkspace(employee) {
  const workspaceId = uuidv4();
  const workspaceName = sanitizeK8sName(`${employee.firstName}-${employee.lastName}`);
  const temporaryPassword = generateSecurePassword();

  try {
    // 1. Store temporary password in SSM Parameter Store (encrypted)
    await ssmService.storeTemporaryPassword(employee.employeeId, temporaryPassword);
    logger.info(`Temporary password stored in SSM for employee ${employee.employeeId}`);
    
    // 2. Create PersistentVolumeClaim
    await createPVC(workspaceName);
    
    // 3. Create Secret for workspace credentials (still needed for code-server)
    await createSecret(workspaceName, temporaryPassword);
    
    // 4. Create Pod for workspace
    await createPod(workspaceName, employee, workspaceId);
    
    // 5. Create Service (LoadBalancer type for external access)
    await createService(workspaceName);
    
    // 6. Use placeholder URL initially (LoadBalancer takes 2-5 minutes)
    const workspaceUrl = `http://${workspaceName}.workspaces.svc.cluster.local`;
    
    // 7. Save workspace metadata to DynamoDB
    const workspace = {
      workspaceId,
      employeeId: employee.employeeId,
      name: workspaceName,
      url: workspaceUrl,
      status: 'provisioning',
      createdAt: new Date().toISOString(),
      credentials: {
        username: 'coder',
        // Password stored securely in SSM, not in DynamoDB
      }
    };
    
    await dynamodbService.createWorkspace(workspace);
    
    // 8. Store workspace metadata in SSM
    await ssmService.storeWorkspaceMetadata(workspace);
    
    // 9. Store audit log
    await ssmService.storeAuditLog('workspace_provisioned', employee.employeeId, {
      workspaceId,
      workspaceName,
      workspaceUrl
    });
    
    // 10. ASYNCHRONOUSLY: Wait for LoadBalancer URL and send email
    getLoadBalancerURLAndSendEmail(workspaceName, employee, workspace, temporaryPassword);
    
    logger.info(`Workspace provisioned: ${workspaceId} for employee ${employee.employeeId}`);
    logger.info(`LoadBalancer URL will be determined asynchronously (2-5 minutes)`);
    logger.info(`Temporary password stored in SSM Parameter Store`);
    
    return {
      ...workspace,
      message: 'Workspace provisioning started. Welcome email will be sent once LoadBalancer is ready.'
    };
  } catch (error) {
    logger.error(`Error provisioning workspace for ${employee.employeeId}:`, error);
    // Cleanup on error
    await cleanupWorkspace(workspaceName);
    throw error;
  }
}

/**
 * Deprovision workspace for an employee
 */
async function deprovisionWorkspace(employeeId) {
  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(employeeId);
    if (!workspace) {
      logger.warn(`No workspace found for employee ${employeeId}`);
      return;
    }

    const workspaceName = workspace.name;
    
    // Delete Kubernetes resources
    await cleanupWorkspace(workspaceName);
    
    // Delete from DynamoDB
    await dynamodbService.deleteWorkspace(workspace.workspaceId);
    
    // Delete temporary password from SSM
    await ssmService.deleteTemporaryPassword(employeeId);
    
    // Store audit log
    await ssmService.storeAuditLog('workspace_deprovisioned', employeeId, {
      workspaceId: workspace.workspaceId,
      workspaceName
    });
    
    logger.info(`Workspace deprovisioned: ${workspace.workspaceId} for employee ${employeeId}`);
  } catch (error) {
    logger.error(`Error deprovisioning workspace for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Get workspace status
 */
async function getWorkspaceStatus(workspaceId) {
  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(workspaceId);
    if (!workspace) {
      return { status: 'not_found' };
    }

    // Check pod status
    const podResponse = await k8sApi.readNamespacedPod(workspace.name, WORKSPACE_NAMESPACE);
    const pod = podResponse.body;
    
    return {
      status: pod.status.phase.toLowerCase(),
      ready: pod.status.conditions?.find(c => c.type === 'Ready')?.status === 'True',
      url: workspace.url
    };
  } catch (error) {
    logger.error(`Error getting workspace status for ${workspaceId}:`, error);
    return { status: 'error', error: error.message };
  }
}

// Helper functions
async function createPVC(name) {
  const pvcName = `${name}-pvc`;
  const pvc = {
    apiVersion: 'v1',
    kind: 'PersistentVolumeClaim',
    metadata: {
      name: pvcName,
      namespace: WORKSPACE_NAMESPACE
    },
    spec: {
      accessModes: ['ReadWriteOnce'],
      storageClassName: 'workspace-storage',
      resources: {
        requests: {
          storage: '10Gi'
        }
      }
    }
  };

  try {
    await k8sApi.createNamespacedPersistentVolumeClaim(WORKSPACE_NAMESPACE, pvc);
  } catch (error) {
    // Handle 409 Conflict - PVC already exists (likely from previous failed attempt)
    if (error.statusCode === 409) {
      logger.warn(`PVC ${pvcName} already exists, deleting and recreating...`);
      try {
        // Delete existing PVC
        await k8sApi.deleteNamespacedPersistentVolumeClaim(pvcName, WORKSPACE_NAMESPACE);
        // Wait a bit for deletion to propagate
        await new Promise(resolve => setTimeout(resolve, 2000));
        // Retry creation
        await k8sApi.createNamespacedPersistentVolumeClaim(WORKSPACE_NAMESPACE, pvc);
        logger.info(`PVC ${pvcName} recreated successfully`);
      } catch (retryError) {
        logger.error(`Failed to recreate PVC ${pvcName}:`, retryError);
        throw retryError;
      }
    } else {
      throw error;
    }
  }
}

async function createSecret(name, password) {
  const secretName = `${name}-secret`;
  const secret = {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      name: secretName,
      namespace: WORKSPACE_NAMESPACE
    },
    type: 'Opaque',
    stringData: {
      password: password
    }
  };

  try {
    await k8sApi.createNamespacedSecret(WORKSPACE_NAMESPACE, secret);
  } catch (error) {
    // Handle 409 Conflict - Secret already exists
    if (error.statusCode === 409) {
      logger.warn(`Secret ${secretName} already exists, deleting and recreating...`);
      try {
        await k8sApi.deleteNamespacedSecret(secretName, WORKSPACE_NAMESPACE);
        await new Promise(resolve => setTimeout(resolve, 2000));
        await k8sApi.createNamespacedSecret(WORKSPACE_NAMESPACE, secret);
        logger.info(`Secret ${secretName} recreated successfully`);
      } catch (retryError) {
        logger.error(`Failed to recreate Secret ${secretName}:`, retryError);
        throw retryError;
      }
    } else {
      throw error;
    }
  }
}

async function createPod(name, employee, workspaceId) {
  const pod = {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      name: name,
      namespace: WORKSPACE_NAMESPACE,
      labels: {
        app: 'workspace',
        employee: name,
        role: employee.role,
        workspaceId: workspaceId
      }
    },
    spec: {
      serviceAccountName: 'workspace-provisioner',
      containers: [{
        name: 'code-server',
        image: `${ECR_REGISTRY}/employee-workspace:latest`,
        imagePullPolicy: 'Always',
        ports: [{
          containerPort: 8080,
          name: 'http'
        }],
        env: [
          { name: 'EMPLOYEE_ID', value: employee.employeeId },
          { name: 'EMPLOYEE_EMAIL', value: employee.email },
          { name: 'EMPLOYEE_ROLE', value: employee.role },
          { 
            name: 'PASSWORD', 
            valueFrom: { 
              secretKeyRef: { 
                name: `${name}-secret`, 
                key: 'password' 
              } 
            } 
          }
        ],
        volumeMounts: [
          { name: 'workspace-storage', mountPath: '/home/coder/workspace' },
          { name: 'tmp', mountPath: '/tmp' }
        ],
        resources: {
          requests: { memory: '1Gi', cpu: '500m' },
          limits: { memory: '2Gi', cpu: '1000m' }
        },
        securityContext: {
          runAsNonRoot: true,
          runAsUser: 1000,
          allowPrivilegeEscalation: false,
          capabilities: { drop: ['ALL'] }
        }
      }],
      volumes: [
        { 
          name: 'workspace-storage', 
          persistentVolumeClaim: { claimName: `${name}-pvc` } 
        },
        { name: 'tmp', emptyDir: {} }
      ]
    }
  };

  await k8sApi.createNamespacedPod(WORKSPACE_NAMESPACE, pod);
}

async function createService(name) {
  const service = {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: name,
      namespace: WORKSPACE_NAMESPACE,
      annotations: {
        'service.beta.kubernetes.io/aws-load-balancer-type': 'nlb',
        'service.beta.kubernetes.io/aws-load-balancer-scheme': 'internet-facing'
      }
    },
    spec: {
      selector: {
        employee: name
      },
      ports: [{
        protocol: 'TCP',
        port: 80,
        targetPort: 8080
      }],
      type: 'LoadBalancer'
    }
  };

  try {
    const result = await k8sApi.createNamespacedService(WORKSPACE_NAMESPACE, service);
    return result.body.metadata.name;
  } catch (error) {
    // Handle 409 Conflict - Service already exists or being deleted
    if (error.statusCode === 409) {
      logger.warn(`Service ${name} already exists or being deleted, waiting for deletion...`);
      try {
        // Try to delete if it exists
        await k8sApi.deleteNamespacedService(name, WORKSPACE_NAMESPACE).catch(() => {});
        
        // Wait for service to be fully deleted (check every 2 seconds, max 30 seconds)
        let deleted = false;
        for (let i = 0; i < 15; i++) {
          await new Promise(resolve => setTimeout(resolve, 2000));
          try {
            await k8sApi.readNamespacedService(name, WORKSPACE_NAMESPACE);
            logger.info(`Waiting for Service ${name} deletion... (${i+1}/15)`);
          } catch (e) {
            if (e.statusCode === 404) {
              deleted = true;
              logger.info(`Service ${name} fully deleted`);
              break;
            }
          }
        }
        
        if (!deleted) {
          logger.warn(`Service ${name} still exists after 30s, proceeding anyway...`);
        }
        
        // Retry creation
        const result = await k8sApi.createNamespacedService(WORKSPACE_NAMESPACE, service);
        logger.info(`Service ${name} recreated successfully`);
        return result.body.metadata.name;
      } catch (retryError) {
        logger.error(`Failed to recreate Service ${name}:`, retryError);
        throw retryError;
      }
    } else {
      throw error;
    }
  }
}

async function getLoadBalancerURL(name) {
  // Wait for LoadBalancer to get external IP/hostname
  let retries = 0;
  const maxRetries = 30; // Wait up to 5 minutes (30 * 10 seconds)
  
  while (retries < maxRetries) {
    try {
      const service = await k8sApi.readNamespacedService(name, WORKSPACE_NAMESPACE);
      const loadBalancer = service.body.status?.loadBalancer;
      
      if (loadBalancer?.ingress && loadBalancer.ingress.length > 0) {
        const hostname = loadBalancer.ingress[0].hostname || loadBalancer.ingress[0].ip;
        if (hostname) {
          return `http://${hostname}`;
        }
      }
    } catch (error) {
      logger.warn(`Error checking LoadBalancer status: ${error.message}`);
    }
    
    await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
    retries++;
  }
  
  // Fallback if LoadBalancer is not ready yet
  logger.warn(`LoadBalancer not ready after ${maxRetries} retries for ${name}`);
  return `http://${name}.${WORKSPACE_NAMESPACE}.svc.cluster.local`;
}

/**
 * Asynchronously wait for LoadBalancer URL and send welcome email
 */
async function getLoadBalancerURLAndSendEmail(workspaceName, employee, workspace, temporaryPassword) {
  try {
    logger.info(`Starting async LoadBalancer check for ${workspaceName}...`);
    
    // Get the actual LoadBalancer URL (waits up to 5 minutes)
    const loadBalancerUrl = await getLoadBalancerURL(workspaceName);
    
    // Update workspace with real URL
    workspace.url = loadBalancerUrl;
    
    // Update DynamoDB with real URL
    await dynamodbService.updateWorkspace(workspace.workspaceId, { url: loadBalancerUrl });
    
    logger.info(`LoadBalancer ready for ${workspaceName}: ${loadBalancerUrl}`);
    
    // Send welcome email with real LoadBalancer URL
    const result = await emailService.sendWelcomeEmail(employee, workspace, temporaryPassword);
    logger.info(`Welcome email sent to ${employee.email}, MessageId: ${result.messageId}`);
    
    // Store audit log for email sent
    await ssmService.storeAuditLog('welcome_email_sent', employee.employeeId, {
      messageId: result.messageId,
      recipient: employee.email,
      workspaceUrl: loadBalancerUrl
    });
  } catch (error) {
    logger.error(`Failed to get LoadBalancer URL or send email for ${workspaceName}:`, error);
  }
}

async function cleanupWorkspace(name) {
  try {
    // Delete in reverse order (no ingress anymore, using LoadBalancer)
    await k8sApi.deleteNamespacedService(name, WORKSPACE_NAMESPACE).catch(() => {});
    await k8sApi.deleteNamespacedPod(name, WORKSPACE_NAMESPACE).catch(() => {});
    await k8sApi.deleteNamespacedSecret(`${name}-secret`, WORKSPACE_NAMESPACE).catch(() => {});
    await k8sApi.deleteNamespacedPersistentVolumeClaim(`${name}-pvc`, WORKSPACE_NAMESPACE).catch(() => {});
  } catch (error) {
    logger.error(`Error cleaning up workspace ${name}:`, error);
  }
}

function generateSecurePassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

module.exports = {
  provisionWorkspace,
  deprovisionWorkspace,
  getWorkspaceStatus
};
