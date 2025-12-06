const k8s = require('@kubernetes/client-node');
const { v4: uuidv4 } = require('uuid');
const dynamodbService = require('./dynamodb');
const ssmService = require('./ssm');
const emailService = require('./email');
const dnsService = require('./dns');
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
const AD_DOMAIN = process.env.AD_DOMAIN || 'innovatech.local';

// Department to image mapping (using official Kasm images for faster startup)
const DEPARTMENT_IMAGES = {
  'infra': 'kasmweb/desktop:1.14.0',
  'infrastructure': 'kasmweb/desktop:1.14.0',
  'dev': 'kasmweb/desktop:1.14.0',
  'development': 'kasmweb/desktop:1.14.0',
  'developer': 'kasmweb/desktop:1.14.0',
  'hr': 'kasmweb/desktop:1.14.0',
  'human_resources': 'kasmweb/desktop:1.14.0',
  'default': 'kasmweb/desktop:1.14.0'
};

// Department resource configurations
const DEPARTMENT_RESOURCES = {
  'infra': {
    requests: { cpu: '1', memory: '2Gi' },
    limits: { cpu: '2', memory: '4Gi' },
    storage: '20Gi'
  },
  'infrastructure': {
    requests: { cpu: '1', memory: '2Gi' },
    limits: { cpu: '2', memory: '4Gi' },
    storage: '20Gi'
  },
  'dev': {
    requests: { cpu: '1500m', memory: '3Gi' },
    limits: { cpu: '3', memory: '6Gi' },
    storage: '50Gi'
  },
  'development': {
    requests: { cpu: '1500m', memory: '3Gi' },
    limits: { cpu: '3', memory: '6Gi' },
    storage: '50Gi'
  },
  'developer': {
    requests: { cpu: '1500m', memory: '3Gi' },
    limits: { cpu: '3', memory: '6Gi' },
    storage: '50Gi'
  },
  'hr': {
    requests: { cpu: '500m', memory: '1Gi' },
    limits: { cpu: '1500m', memory: '3Gi' },
    storage: '10Gi'
  },
  'human_resources': {
    requests: { cpu: '500m', memory: '1Gi' },
    limits: { cpu: '1500m', memory: '3Gi' },
    storage: '10Gi'
  },
  'default': {
    requests: { cpu: '500m', memory: '1Gi' },
    limits: { cpu: '1', memory: '2Gi' },
    storage: '10Gi'
  }
};

/**
 * Sanitize name for Kubernetes resource naming
 * Must match: [a-z0-9]([-a-z0-9]*[a-z0-9])?
 */
function sanitizeK8sName(name) {
  return name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9-]/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/-+/g, '-')
    .substring(0, 63);
}

/**
 * Generate secure password for VNC access
 */
function generateSecurePassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  const symbols = '!@#$%';
  let password = '';
  
  // Ensure at least one of each type
  password += chars.charAt(Math.floor(Math.random() * 26)); // uppercase
  password += chars.charAt(Math.floor(Math.random() * 26) + 26); // lowercase
  password += chars.charAt(Math.floor(Math.random() * 8) + 52); // number
  password += symbols.charAt(Math.floor(Math.random() * symbols.length)); // symbol
  
  // Fill rest with random chars
  for (let i = 0; i < 8; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

/**
 * Get department from employee data
 */
function getDepartment(employee) {
  const dept = (employee.department || employee.role || 'default').toLowerCase();
  return dept;
}

/**
 * Provision a new Kasm workspace for an employee
 */
async function provisionWorkspace(employee) {
  if (!initK8sClient()) {
    throw new Error('Kubernetes client not available. Cannot provision workspace.');
  }

  // Check if employee already has an active workspace
  const existingWorkspace = await dynamodbService.getWorkspaceByEmployee(employee.employeeId);
  if (existingWorkspace && existingWorkspace.status === 'active') {
    logger.warn(`Employee ${employee.employeeId} already has an active workspace: ${existingWorkspace.workspaceId}`);
    throw new Error(`Employee already has an active workspace. Delete the existing workspace first.`);
  }

  const workspaceId = uuidv4();
  const department = getDepartment(employee);
  const workspaceName = sanitizeK8sName(`ws-${workspaceId}`);
  const vncPassword = generateSecurePassword();

  logger.info(`Provisioning Kasm workspace for ${employee.employeeId}, department: ${department}`);

  try {
    // 1. Ensure namespace exists
    await ensureNamespace();

    // 2. Create Secret for VNC password
    await createWorkspaceSecret(workspaceName, vncPassword, employee);
    logger.info(`Secret created for ${workspaceName}`);

    // 3. Create PVC for workspace data
    await createWorkspacePVC(workspaceName, department);
    logger.info(`PVC created for ${workspaceName}`);

    // 4. Create Kasm workspace Pod
    await createKasmPod(workspaceName, employee, department, workspaceId);
    logger.info(`Kasm pod created for ${workspaceName}`);

    // 5. Create Service for workspace access
    await createWorkspaceService(workspaceName, employee.employeeId);
    logger.info(`Service created for ${workspaceName}`);

    // 6. Wait for pod to be ready and get NodePort + Node IP
    const { nodePort, nodeIp } = await waitForWorkspaceReady(workspaceName, 300);
    logger.info(`Workspace ready on node ${nodeIp}:${nodePort}`);

    // 7. Create personal DNS record (firstname.lastname.innovatech.local)
    let accessUrl;
    let dnsName;
    try {
      const dnsResult = await dnsService.createWorkspaceDnsRecord(employee, nodeIp, nodePort);
      accessUrl = dnsResult.url;
      dnsName = dnsResult.dnsName;
      logger.info(`DNS record created: ${dnsName} -> ${nodeIp}`);
    } catch (dnsError) {
      logger.warn(`DNS creation failed, using fallback URL: ${dnsError.message}`);
      accessUrl = `https://${nodeIp}:${nodePort}`;
      dnsName = null;
    }

    // 8. Save workspace metadata
    const workspace = {
      workspaceId,
      employeeId: employee.employeeId,
      name: workspaceName,
      department,
      url: accessUrl,
      dnsName: dnsName,
      nodeIp: nodeIp,
      nodePort: nodePort,
      vncPort: 6901,
      status: 'active',
      type: 'kasm',
      createdAt: new Date().toISOString(),
      credentials: {
        username: employee.firstName.toLowerCase(),
        password: vncPassword
      }
    };

    await dynamodbService.createWorkspace(workspace);
    logger.info(`Workspace metadata saved to DynamoDB`);

    // 9. Store password in SSM
    try {
      await ssmService.storeTemporaryPassword(employee.employeeId, vncPassword);
    } catch (ssmError) {
      logger.warn(`Failed to store password in SSM: ${ssmError.message}`);
    }

    // 10. Send welcome email
    emailService.sendWelcomeEmail(employee, workspace, vncPassword)
      .then(() => logger.info(`Welcome email sent to ${employee.email}`))
      .catch(err => logger.warn(`Failed to send welcome email: ${err.message}`));

    return workspace;

  } catch (error) {
    logger.error(`Error provisioning workspace for ${employee.employeeId}:`, error);
    await cleanupWorkspace(workspaceName);
    throw error;
  }
}

/**
 * Ensure workspaces namespace exists
 */
async function ensureNamespace() {
  try {
    await k8sApi.readNamespace(WORKSPACE_NAMESPACE);
    logger.info(`Namespace ${WORKSPACE_NAMESPACE} already exists`);
  } catch (error) {
    if (error.statusCode === 404) {
      await k8sApi.createNamespace({
        apiVersion: 'v1',
        kind: 'Namespace',
        metadata: {
          name: WORKSPACE_NAMESPACE,
          labels: {
            name: WORKSPACE_NAMESPACE,
            purpose: 'employee-workspaces'
          }
        }
      });
      logger.info(`Namespace ${WORKSPACE_NAMESPACE} created`);
    } else {
      throw error;
    }
  }
}

/**
 * Create workspace secret with VNC password and employee info
 */
async function createWorkspaceSecret(name, vncPassword, employee) {
  const secretName = `${name}-secret`;
  const secret = {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      name: secretName,
      namespace: WORKSPACE_NAMESPACE,
      labels: {
        app: 'workspace',
        employee: employee.employeeId,
        type: 'kasm-workspace'
      }
    },
    type: 'Opaque',
    stringData: {
      'vnc-password': vncPassword,
      'employee-id': employee.employeeId,
      'employee-email': employee.email || ''
    }
  };

  try {
    await k8sApi.createNamespacedSecret(WORKSPACE_NAMESPACE, secret);
  } catch (error) {
    if (error.statusCode === 409) {
      await k8sApi.deleteNamespacedSecret(secretName, WORKSPACE_NAMESPACE);
      await new Promise(resolve => setTimeout(resolve, 1000));
      await k8sApi.createNamespacedSecret(WORKSPACE_NAMESPACE, secret);
    } else {
      throw error;
    }
  }
}

/**
 * Create PVC for workspace data persistence
 */
async function createWorkspacePVC(name, department) {
  const pvcName = `${name}-pvc`;
  const resources = DEPARTMENT_RESOURCES[department] || DEPARTMENT_RESOURCES.default;
  
  const pvc = {
    apiVersion: 'v1',
    kind: 'PersistentVolumeClaim',
    metadata: {
      name: pvcName,
      namespace: WORKSPACE_NAMESPACE,
      labels: {
        app: 'workspace',
        type: 'kasm-workspace'
      }
    },
    spec: {
      accessModes: ['ReadWriteOnce'],
      storageClassName: 'gp2',
      resources: {
        requests: {
          storage: resources.storage
        }
      }
    }
  };

  try {
    await k8sApi.createNamespacedPersistentVolumeClaim(WORKSPACE_NAMESPACE, pvc);
  } catch (error) {
    if (error.statusCode === 409) {
      logger.warn(`PVC ${pvcName} already exists, using existing`);
    } else {
      throw error;
    }
  }
}

/**
 * Create Kasm workspace pod
 */
async function createKasmPod(name, employee, department, workspaceId) {
  const image = DEPARTMENT_IMAGES[department] || DEPARTMENT_IMAGES.default;
  const resources = DEPARTMENT_RESOURCES[department] || DEPARTMENT_RESOURCES.default;
  
  const pod = {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      name: name,
      namespace: WORKSPACE_NAMESPACE,
      labels: {
        app: 'workspace',
        department: department,
        employee: employee.employeeId,
        'workspace-id': workspaceId,
        type: 'kasm-workspace'
      },
      annotations: {
        'workspace.innovatech.local/employee-name': `${employee.firstName} ${employee.lastName}`,
        'workspace.innovatech.local/created-at': new Date().toISOString()
      }
    },
    spec: {
      serviceAccountName: 'workspace-user',
      securityContext: {
        runAsUser: 1000,
        runAsGroup: 1000,
        fsGroup: 1000
      },
      containers: [{
        name: 'workspace',
        image: image,
        imagePullPolicy: 'Always',
        ports: [
          { name: 'vnc', containerPort: 6901, protocol: 'TCP' }
        ],
        env: [
          { name: 'EMPLOYEE_ID', value: employee.employeeId },
          { name: 'EMPLOYEE_EMAIL', value: employee.email || '' },
          { name: 'DEPARTMENT', value: department },
          { name: 'AD_DOMAIN', value: AD_DOMAIN },
          { 
            name: 'VNC_PW', 
            valueFrom: { 
              secretKeyRef: { 
                name: `${name}-secret`, 
                key: 'vnc-password' 
              } 
            } 
          }
        ],
        resources: {
          requests: resources.requests,
          limits: resources.limits
        },
        volumeMounts: [
          {
            name: 'workspace-data',
            mountPath: '/home/kasm-user/workspace'
          },
          {
            name: 'shm',
            mountPath: '/dev/shm'
          }
        ],
        livenessProbe: {
          tcpSocket: {
            port: 6901
          },
          initialDelaySeconds: 60,
          periodSeconds: 30,
          timeoutSeconds: 10,
          failureThreshold: 5
        },
        readinessProbe: {
          tcpSocket: {
            port: 6901
          },
          initialDelaySeconds: 15,
          periodSeconds: 5,
          timeoutSeconds: 3,
          successThreshold: 1,
          failureThreshold: 30
        }
      }],
      volumes: [
        {
          name: 'workspace-data',
          persistentVolumeClaim: {
            claimName: `${name}-pvc`
          }
        },
        {
          name: 'shm',
          emptyDir: {
            medium: 'Memory',
            sizeLimit: '2Gi'
          }
        }
      ],
      restartPolicy: 'Always',
      dnsPolicy: 'ClusterFirst',
      terminationGracePeriodSeconds: 30
    }
  };

  try {
    await k8sApi.createNamespacedPod(WORKSPACE_NAMESPACE, pod);
  } catch (error) {
    if (error.statusCode === 409) {
      logger.warn(`Pod ${name} already exists, deleting and recreating`);
      await k8sApi.deleteNamespacedPod(name, WORKSPACE_NAMESPACE);
      await new Promise(resolve => setTimeout(resolve, 5000));
      await k8sApi.createNamespacedPod(WORKSPACE_NAMESPACE, pod);
    } else {
      throw error;
    }
  }
}

/**
 * Create service for workspace access
 */
async function createWorkspaceService(name, employeeId) {
  const serviceName = `${name}-svc`;
  
  const service = {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: serviceName,
      namespace: WORKSPACE_NAMESPACE,
      labels: {
        app: 'workspace',
        employee: employeeId,
        type: 'kasm-workspace'
      }
    },
    spec: {
      type: 'NodePort',
      ports: [
        {
          name: 'vnc',
          port: 6901,
          targetPort: 6901,
          protocol: 'TCP'
        }
      ],
      selector: {
        app: 'workspace',
        employee: employeeId
      }
    }
  };

  try {
    await k8sApi.createNamespacedService(WORKSPACE_NAMESPACE, service);
  } catch (error) {
    if (error.statusCode === 409) {
      logger.warn(`Service ${serviceName} already exists, using existing`);
    } else {
      throw error;
    }
  }
}

/**
 * Wait for workspace pod to be ready and return node details
 */
async function waitForWorkspaceReady(name, timeoutSeconds = 120) {
  const startTime = Date.now();
  const timeoutMs = timeoutSeconds * 1000;
  
  while (Date.now() - startTime < timeoutMs) {
    try {
      const podResponse = await k8sApi.readNamespacedPod(name, WORKSPACE_NAMESPACE);
      const pod = podResponse.body;
      
      if (pod.status.phase === 'Running') {
        const ready = pod.status.conditions?.find(c => c.type === 'Ready')?.status === 'True';
        if (ready) {
          // Get service NodePort
          const svcResponse = await k8sApi.readNamespacedService(`${name}-svc`, WORKSPACE_NAMESPACE);
          const nodePort = svcResponse.body.spec.ports[0].nodePort;
          
          // Get the node IP where the pod is running
          const nodeName = pod.spec.nodeName;
          const nodeResponse = await k8sApi.readNode(nodeName);
          const nodeIp = nodeResponse.body.status.addresses.find(
            addr => addr.type === 'InternalIP'
          )?.address;
          
          if (!nodeIp) {
            throw new Error(`Could not determine node IP for ${nodeName}`);
          }
          
          logger.info(`Workspace ${name} ready on node ${nodeName} (${nodeIp}:${nodePort})`);
          
          return { nodePort, nodeIp, nodeName };
        }
      }
      
      if (pod.status.phase === 'Failed') {
        throw new Error('Pod failed to start');
      }
    } catch (error) {
      if (error.statusCode !== 404) {
        logger.warn(`Error checking pod status: ${error.message}`);
      }
    }
    
    await new Promise(resolve => setTimeout(resolve, 5000));
  }
  
  throw new Error(`Workspace did not become ready within ${timeoutSeconds} seconds`);
}

/**
 * Deprovision workspace for an employee
 */
async function deprovisionWorkspace(employeeId) {
  if (!initK8sClient()) {
    throw new Error('Kubernetes client not available');
  }

  try {
    // Get employee data for DNS cleanup
    const employee = await dynamodbService.getEmployee(employeeId);
    
    const workspace = await dynamodbService.getWorkspaceByEmployee(employeeId);
    if (!workspace) {
      logger.warn(`No workspace found for employee ${employeeId}`);
      return;
    }

    // Clean up Kubernetes resources
    await cleanupWorkspace(workspace.name);
    
    // Delete DNS record
    if (employee && workspace.nodeIp) {
      try {
        await dnsService.deleteWorkspaceDnsRecord(employee, workspace.nodeIp);
        logger.info(`DNS record deleted for ${employeeId}`);
      } catch (dnsError) {
        logger.warn(`Failed to delete DNS record: ${dnsError.message}`);
      }
    }
    
    // Delete workspace from DynamoDB
    await dynamodbService.deleteWorkspace(workspace.workspaceId);
    
    // Delete SSM password
    try {
      await ssmService.deleteTemporaryPassword(employeeId);
    } catch (e) {
      logger.warn(`Failed to delete SSM password: ${e.message}`);
    }
    
    logger.info(`Workspace deprovisioned for employee ${employeeId}`);
  } catch (error) {
    logger.error(`Error deprovisioning workspace for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Cleanup workspace resources
 */
async function cleanupWorkspace(name) {
  const resources = [
    { type: 'Pod', delete: () => k8sApi.deleteNamespacedPod(name, WORKSPACE_NAMESPACE) },
    { type: 'Service', delete: () => k8sApi.deleteNamespacedService(`${name}-svc`, WORKSPACE_NAMESPACE) },
    { type: 'Secret', delete: () => k8sApi.deleteNamespacedSecret(`${name}-secret`, WORKSPACE_NAMESPACE) },
    { type: 'PVC', delete: () => k8sApi.deleteNamespacedPersistentVolumeClaim(`${name}-pvc`, WORKSPACE_NAMESPACE) }
  ];

  for (const resource of resources) {
    try {
      await resource.delete();
      logger.info(`Deleted ${resource.type} for ${name}`);
    } catch (error) {
      if (error.statusCode !== 404) {
        logger.warn(`Failed to delete ${resource.type} for ${name}: ${error.message}`);
      }
    }
  }
}

/**
 * Get workspace status
 */
async function getWorkspaceStatus(employeeId) {
  if (!initK8sClient()) {
    return { status: 'k8s_unavailable' };
  }

  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(employeeId);
    if (!workspace) {
      return { status: 'not_found' };
    }

    const podResponse = await k8sApi.readNamespacedPod(workspace.name, WORKSPACE_NAMESPACE);
    const pod = podResponse.body;
    
    return {
      status: pod.status.phase.toLowerCase(),
      ready: pod.status.conditions?.find(c => c.type === 'Ready')?.status === 'True',
      url: workspace.url,
      department: workspace.department,
      type: workspace.type
    };
  } catch (error) {
    logger.error(`Error getting workspace status for ${employeeId}:`, error);
    return { status: 'error', error: error.message };
  }
}

/**
 * List all workspaces
 */
async function listWorkspaces() {
  if (!initK8sClient()) {
    return [];
  }

  try {
    const podsResponse = await k8sApi.listNamespacedPod(
      WORKSPACE_NAMESPACE,
      undefined, undefined, undefined, undefined,
      'type=kasm-workspace'
    );
    
    return podsResponse.body.items.map(pod => ({
      name: pod.metadata.name,
      employee: pod.metadata.labels.employee,
      department: pod.metadata.labels.department,
      status: pod.status.phase,
      ready: pod.status.conditions?.find(c => c.type === 'Ready')?.status === 'True',
      createdAt: pod.metadata.creationTimestamp
    }));
  } catch (error) {
    logger.error('Error listing workspaces:', error);
    return [];
  }
}

/**
 * Restart workspace for an employee
 */
async function restartWorkspace(employeeId) {
  if (!initK8sClient()) {
    throw new Error('Kubernetes client not available');
  }

  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(employeeId);
    if (!workspace) {
      throw new Error(`No workspace found for employee ${employeeId}`);
    }

    // Delete pod (it will be recreated by Kubernetes since restartPolicy: Always)
    await k8sApi.deleteNamespacedPod(workspace.name, WORKSPACE_NAMESPACE);
    logger.info(`Workspace ${workspace.name} restarted for employee ${employeeId}`);
    
    return { success: true, message: 'Workspace restarting' };
  } catch (error) {
    logger.error(`Error restarting workspace for ${employeeId}:`, error);
    throw error;
  }
}

module.exports = {
  provisionWorkspace,
  deprovisionWorkspace,
  getWorkspaceStatus,
  listWorkspaces,
  restartWorkspace,
  cleanupWorkspace,
  sanitizeK8sName,
  generateSecurePassword,
  DEPARTMENT_IMAGES,
  DEPARTMENT_RESOURCES
};
