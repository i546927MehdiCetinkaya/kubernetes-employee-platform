const k8s = require('@kubernetes/client-node');
const { v4: uuidv4 } = require('uuid');
const dynamodbService = require('./dynamodb');
const ssmService = require('./ssm');
const emailService = require('./email');
const logger = require('../utils/logger');

// Initialize Kubernetes client with fallback
const kc = new k8s.KubeConfig();
let k8sApi = null;
let k8sAppsApi = null;
let k8sNetworkingApi = null;
let k8sInitialized = false;

function initK8sClient() {
  if (k8sInitialized) return true;
  
  try {
    // Try to load in-cluster config first
    kc.loadFromCluster();
    k8sApi = kc.makeApiClient(k8s.CoreV1Api);
    k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);
    k8sNetworkingApi = kc.makeApiClient(k8s.NetworkingV1Api);
    k8sInitialized = true;
    logger.info('Kubernetes client initialized from in-cluster config');
    return true;
  } catch (error) {
    logger.warn('Failed to load in-cluster config, trying default config:', error.message);
    try {
      kc.loadFromDefault();
      k8sApi = kc.makeApiClient(k8s.CoreV1Api);
      k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);
      k8sNetworkingApi = kc.makeApiClient(k8s.NetworkingV1Api);
      k8sInitialized = true;
      logger.info('Kubernetes client initialized from default config');
      return true;
    } catch (defaultError) {
      logger.error('Failed to initialize Kubernetes client:', defaultError.message);
      return false;
    }
  }
}

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
  // Initialize Kubernetes client
  if (!initK8sClient()) {
    throw new Error('Kubernetes client not available. Cannot provision workspace.');
  }

  const workspaceId = uuidv4();
  const workspaceName = sanitizeK8sName(`${employee.firstName}-${employee.lastName}`);
  const temporaryPassword = generateSecurePassword();

  logger.info(`Starting workspace provisioning for ${employee.employeeId}, name: ${workspaceName}`);

  try {
    // 1. Store temporary password in SSM Parameter Store (encrypted)
    try {
      await ssmService.storeTemporaryPassword(employee.employeeId, temporaryPassword);
      logger.info(`Step 1: Temporary password stored in SSM for employee ${employee.employeeId}`);
    } catch (ssmError) {
      logger.warn(`Step 1 failed (SSM): ${ssmError.message}, continuing...`);
    }
    
    // 2. Create Secret for workspace credentials (still needed for code-server)
    try {
      await createSecret(workspaceName, temporaryPassword);
      logger.info(`Step 2: Secret created for ${workspaceName}`);
    } catch (secretError) {
      logger.error(`Step 2 failed (Secret): ${secretError.message}`);
      throw secretError;
    }
    
    // 3. Create Pod for workspace (uses emptyDir, no PVC needed)
    try {
      await createPod(workspaceName, employee, workspaceId);
      logger.info(`Step 3: Pod created for ${workspaceName}`);
    } catch (podError) {
      logger.error(`Step 3 failed (Pod): ${podError.message}`);
      throw podError;
    }
    
    // 4. Create Service (LoadBalancer type for external access)
    try {
      await createService(workspaceName);
      logger.info(`Step 4: Service created for ${workspaceName}`);
    } catch (serviceError) {
      logger.error(`Step 4 failed (Service): ${serviceError.message}`);
      throw serviceError;
    }
    
    // 5. Wait for LoadBalancer URL (up to 2 minutes)
    logger.info(`Step 5: Waiting for LoadBalancer URL...`);
    const workspaceUrl = await getLoadBalancerURLFast(workspaceName);
    logger.info(`Step 5: LoadBalancer URL obtained: ${workspaceUrl}`);
    
    // 6. Save workspace metadata to DynamoDB with real URL
    const workspace = {
      workspaceId,
      employeeId: employee.employeeId,
      name: workspaceName,
      url: workspaceUrl,
      status: 'active',
      createdAt: new Date().toISOString(),
      credentials: {
        username: 'coder',
        password: temporaryPassword
      }
    };
    
    try {
      await dynamodbService.createWorkspace(workspace);
      logger.info(`Step 6: Workspace metadata saved to DynamoDB`);
    } catch (dbError) {
      logger.warn(`Step 6 failed (DynamoDB): ${dbError.message}, continuing...`);
    }
    
    // 7. Store workspace metadata in SSM (optional)
    try {
      await ssmService.storeWorkspaceMetadata(workspace);
      logger.info(`Step 7: Workspace metadata stored in SSM`);
    } catch (ssmMetaError) {
      logger.warn(`Step 7 failed (SSM Metadata): ${ssmMetaError.message}, continuing...`);
    }
    
    // 8. Store audit log (optional)
    try {
      await ssmService.storeAuditLog('workspace_provisioned', employee.employeeId, {
        workspaceId,
        workspaceName,
        workspaceUrl
      });
      logger.info(`Step 8: Audit log stored`);
    } catch (auditError) {
      logger.warn(`Step 8 failed (Audit): ${auditError.message}, continuing...`);
    }
    
    // 9. Send welcome email (async, don't wait)
    emailService.sendWelcomeEmail(employee, workspace, temporaryPassword)
      .then(result => logger.info(`Welcome email sent to ${employee.email}`))
      .catch(err => logger.warn(`Failed to send welcome email: ${err.message}`));
    
    logger.info(`Workspace provisioned: ${workspaceId} for employee ${employee.employeeId}`);
    
    return workspace;
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
  // Initialize Kubernetes client
  if (!initK8sClient()) {
    throw new Error('Kubernetes client not available. Cannot deprovision workspace.');
  }

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
  // Initialize Kubernetes client
  if (!initK8sClient()) {
    return { status: 'k8s_unavailable', error: 'Kubernetes client not available' };
  }

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
      password: password,
      'vnc-password': password  // Also store as vnc-password for rebuild endpoint
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
        employeeId: employee.employeeId,
        role: employee.role,
        workspaceId: workspaceId
      }
    },
    spec: {
      // Use default service account - no special permissions needed for workspaces
      automountServiceAccountToken: false,
      containers: [{
        name: 'linux-desktop',
        image: `${ECR_REGISTRY}/employee-workspace:latest`,
        imagePullPolicy: 'Always',
        ports: [{
          containerPort: 6080,
          name: 'novnc'
        }],
        env: [
          { name: 'EMPLOYEE_ID', value: employee.employeeId },
          { name: 'EMPLOYEE_EMAIL', value: employee.email },
          { name: 'EMPLOYEE_ROLE', value: employee.role },
          { name: 'USER', value: 'employee' },
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
          { name: 'workspace-storage', mountPath: '/home/employee/workspace' },
          { name: 'tmp', mountPath: '/tmp' }
        ],
        resources: {
          requests: { memory: '1Gi', cpu: '500m' },
          limits: { memory: '2Gi', cpu: '1000m' }
        },
        // Linux desktop needs root for VNC setup, then drops to user
        securityContext: {
          runAsUser: 0,
          allowPrivilegeEscalation: true
        }
      }],
      volumes: [
        // Use emptyDir for now (no EBS CSI driver issues)
        // TODO: Switch back to PVC once EBS CSI driver is properly configured
        { name: 'workspace-storage', emptyDir: { sizeLimit: '10Gi' } },
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
        targetPort: 6080
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
 * Fast version of getLoadBalancerURL - waits up to 2 minutes with shorter intervals
 */
async function getLoadBalancerURLFast(name) {
  const maxRetries = 24; // Wait up to 2 minutes (24 * 5 seconds)
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      const service = await k8sApi.readNamespacedService(name, WORKSPACE_NAMESPACE);
      const loadBalancer = service.body.status?.loadBalancer;
      
      if (loadBalancer?.ingress && loadBalancer.ingress.length > 0) {
        const hostname = loadBalancer.ingress[0].hostname || loadBalancer.ingress[0].ip;
        if (hostname) {
          logger.info(`LoadBalancer URL ready after ${i * 5} seconds: ${hostname}`);
          return `http://${hostname}`;
        }
      }
    } catch (error) {
      logger.warn(`Error checking LoadBalancer status (attempt ${i+1}): ${error.message}`);
    }
    
    if (i < maxRetries - 1) {
      logger.info(`Waiting for LoadBalancer... (${(i+1) * 5}s / 120s)`);
      await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5 seconds
    }
  }
  
  // If still not ready, throw error instead of using local URL
  throw new Error(`LoadBalancer not ready after 2 minutes for ${name}. Please try again later.`);
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
