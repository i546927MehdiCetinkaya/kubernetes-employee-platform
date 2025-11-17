// RBAC Service - Permission checks per department
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'eu-west-1' });
const dynamodb = DynamoDBDocumentClient.from(client);

const ROLES = {
  ADMIN: 'admin',
  MANAGER: 'manager',
  DEVELOPER: 'developer',
  SALES: 'sales',
  MARKETING: 'marketing',
  OPERATIONS: 'operations'
};

const PERMISSIONS = {
  [ROLES.ADMIN]: {
    departments: ['*'], // All departments
    employees: { read: true, write: true, delete: true },
    workspaces: { read: true, write: true, delete: true },
    folders: ['*'], // All folders
    canManage: true
  },
  [ROLES.MANAGER]: {
    departments: ['own'], // Only own department
    employees: { read: true, write: true, delete: false },
    workspaces: { read: true, write: false, delete: false },
    folders: ['department'], // Department folder only
    canManage: false
  },
  [ROLES.DEVELOPER]: {
    departments: ['own'], // Only own department
    employees: { read: true, write: false, delete: false },
    workspaces: { read: true, write: false, delete: false },
    folders: ['personal'], // Personal folder only
    canManage: false
  },
  [ROLES.SALES]: {
    departments: ['own'],
    employees: { read: true, write: false, delete: false },
    workspaces: { read: true, write: false, delete: false },
    folders: ['personal', 'shared-sales'],
    canManage: false
  },
  [ROLES.MARKETING]: {
    departments: ['own'],
    employees: { read: true, write: false, delete: false },
    workspaces: { read: true, write: false, delete: false },
    folders: ['personal', 'shared-marketing'],
    canManage: false
  },
  [ROLES.OPERATIONS]: {
    departments: ['own'],
    employees: { read: true, write: false, delete: false },
    workspaces: { read: true, write: false, delete: false },
    folders: ['personal', 'shared-operations'],
    canManage: false
  }
};

/**
 * Check if user has permission to access resource
 */
async function checkPermission(employeeId, action, resourceType, resourceId = null) {
  try {
    // Get employee from DynamoDB
    const employee = await getEmployee(employeeId);
    
    if (!employee) {
      return { allowed: false, reason: 'Employee not found' };
    }

    const role = employee.role;
    const department = employee.department;
    const permissions = PERMISSIONS[role];

    if (!permissions) {
      return { allowed: false, reason: 'Invalid role' };
    }

    // Check permission based on resource type
    switch (resourceType) {
      case 'employee':
        return checkEmployeePermission(employee, action, resourceId, permissions);
      
      case 'workspace':
        return checkWorkspacePermission(employee, action, resourceId, permissions);
      
      case 'folder':
        return checkFolderPermission(employee, action, resourceId, permissions);
      
      default:
        return { allowed: false, reason: 'Unknown resource type' };
    }
  } catch (error) {
    console.error('Permission check error:', error);
    return { allowed: false, reason: 'Permission check failed' };
  }
}

/**
 * Check employee resource permission
 */
async function checkEmployeePermission(currentEmployee, action, targetEmployeeId, permissions) {
  const targetEmployee = await getEmployee(targetEmployeeId);
  
  if (!targetEmployee) {
    return { allowed: false, reason: 'Target employee not found' };
  }

  // Admin can access all employees
  if (currentEmployee.role === ROLES.ADMIN) {
    return { allowed: true };
  }

  // Manager can access employees in their department
  if (currentEmployee.role === ROLES.MANAGER) {
    if (currentEmployee.department === targetEmployee.department) {
      if (action === 'read' || action === 'write') {
        return { allowed: true };
      }
    }
    return { allowed: false, reason: 'Managers can only access their department' };
  }

  // Others can only access themselves
  if (currentEmployee.employeeId === targetEmployeeId && action === 'read') {
    return { allowed: true };
  }

  return { allowed: false, reason: 'Insufficient permissions' };
}

/**
 * Check workspace resource permission
 */
async function checkWorkspacePermission(currentEmployee, action, workspaceId, permissions) {
  // Admin can access all workspaces
  if (currentEmployee.role === ROLES.ADMIN) {
    return { allowed: true };
  }

  // Users can only access their own workspace
  if (workspaceId === currentEmployee.employeeId) {
    if (action === 'read') {
      return { allowed: true };
    }
  }

  // Managers can view workspaces in their department
  if (currentEmployee.role === ROLES.MANAGER && action === 'read') {
    const targetEmployee = await getEmployee(workspaceId);
    if (targetEmployee && targetEmployee.department === currentEmployee.department) {
      return { allowed: true };
    }
  }

  return { allowed: false, reason: 'Can only access own workspace' };
}

/**
 * Check folder permission
 */
function checkFolderPermission(currentEmployee, action, folderPath, permissions) {
  const allowedFolders = permissions.folders;

  // Admin has access to all folders
  if (allowedFolders.includes('*')) {
    return { allowed: true };
  }

  // Check personal folder
  if (folderPath.startsWith('/personal/' + currentEmployee.employeeId)) {
    return { allowed: true };
  }

  // Check department folder
  if (allowedFolders.includes('department')) {
    if (folderPath.startsWith('/departments/' + currentEmployee.department)) {
      return { allowed: true };
    }
  }

  // Check shared folders
  for (const folder of allowedFolders) {
    if (folder.startsWith('shared-')) {
      const sharedDept = folder.replace('shared-', '');
      if (folderPath.startsWith('/shared/' + sharedDept)) {
        return { allowed: true };
      }
    }
  }

  return { allowed: false, reason: 'No access to this folder' };
}

/**
 * Get employee from DynamoDB
 */
async function getEmployee(employeeId) {
  const params = {
    TableName: process.env.DYNAMODB_TABLE || 'innovatech-employees',
    Key: { employeeId }
  };

  const result = await dynamodb.send(new GetCommand(params));
  return result.Item;
}

/**
 * Get all employees in department (for managers/admins)
 */
async function getEmployeesByDepartment(currentEmployee) {
  // Check if user can access department employees
  const permissions = PERMISSIONS[currentEmployee.role];
  
  if (!permissions.departments.includes('*') && !permissions.departments.includes('own')) {
    throw new Error('Insufficient permissions');
  }

  const params = {
    TableName: process.env.DYNAMODB_TABLE || 'innovatech-employees',
  };

  // Admin can see all
  if (currentEmployee.role === ROLES.ADMIN) {
    const result = await dynamodb.send(new ScanCommand(params));
    return result.Items;
  }

  // Others see only their department
  params.FilterExpression = 'department = :dept';
  params.ExpressionAttributeValues = {
    ':dept': currentEmployee.department
  };

  const result = await dynamodb.send(new ScanCommand(params));
  return result.Items;
}

/**
 * Get allowed departments for employee based on role
 */
function getAllowedDepartments(employee) {
  const permissions = PERMISSIONS[employee.role];
  
  if (permissions.departments.includes('*')) {
    return ['all'];
  }
  
  if (permissions.departments.includes('own')) {
    return [employee.department];
  }
  
  return [];
}

/**
 * Middleware to check permissions
 */
function requirePermission(resourceType, action) {
  return async (req, res, next) => {
    try {
      const employeeId = req.user?.employeeId || req.headers['x-employee-id'];
      const resourceId = req.params.id || req.params.employeeId;

      if (!employeeId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const permissionCheck = await checkPermission(employeeId, action, resourceType, resourceId);

      if (!permissionCheck.allowed) {
        return res.status(403).json({ 
          error: 'Forbidden', 
          reason: permissionCheck.reason 
        });
      }

      // Attach permission info to request
      req.permissions = permissionCheck;
      next();
    } catch (error) {
      console.error('Permission middleware error:', error);
      res.status(500).json({ error: 'Permission check failed' });
    }
  };
}

module.exports = {
  ROLES,
  PERMISSIONS,
  checkPermission,
  getEmployeesByDepartment,
  getAllowedDepartments,
  requirePermission
};
