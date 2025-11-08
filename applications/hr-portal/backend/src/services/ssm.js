const { SSMClient, GetParameterCommand, PutParameterCommand, DeleteParameterCommand, GetParametersByPathCommand } = require('@aws-sdk/client-ssm');
const logger = require('../utils/logger');

const AWS_REGION = process.env.AWS_REGION || 'eu-west-1';
const CLUSTER_NAME = process.env.CLUSTER_NAME || 'innovatech-employee-lifecycle';

const ssmClient = new SSMClient({ region: AWS_REGION });

/**
 * Store temporary workspace password in SSM Parameter Store
 */
async function storeTemporaryPassword(employeeId, password) {
  const parameterName = `/${CLUSTER_NAME}/workspaces/${employeeId}/temp-password`;
  
  try {
    // First try to create with tags (new parameter)
    try {
      const createCommand = new PutParameterCommand({
        Name: parameterName,
        Value: password,
        Type: 'SecureString',
        Description: `Temporary password for employee ${employeeId}`,
        Tags: [
          { Key: 'EmployeeID', Value: employeeId },
          { Key: 'Type', Value: 'TempPassword' },
          { Key: 'CreatedAt', Value: new Date().toISOString() },
          { Key: 'ExpiresIn', Value: '24h' }
        ]
      });
      await ssmClient.send(createCommand);
    } catch (createError) {
      // If parameter exists, update without tags
      if (createError.name === 'ParameterAlreadyExists') {
        const updateCommand = new PutParameterCommand({
          Name: parameterName,
          Value: password,
          Type: 'SecureString',
          Description: `Temporary password for employee ${employeeId}`,
          Overwrite: true
        });
        await ssmClient.send(updateCommand);
      } else {
        throw createError;
      }
    }
    
    logger.info(`Temporary password stored in SSM for employee ${employeeId}`);
    return { success: true, parameterName };
  } catch (error) {
    logger.error(`Failed to store temporary password in SSM for ${employeeId}:`, error);
    throw new Error(`SSM Parameter Store error: ${error.message}`);
  }
}

/**
 * Get temporary password from SSM (for verification/troubleshooting)
 */
async function getTemporaryPassword(employeeId) {
  const parameterName = `/${CLUSTER_NAME}/workspaces/${employeeId}/temp-password`;
  
  try {
    const command = new GetParameterCommand({
      Name: parameterName,
      WithDecryption: true
    });

    const response = await ssmClient.send(command);
    return response.Parameter.Value;
  } catch (error) {
    if (error.name === 'ParameterNotFound') {
      logger.warn(`No temporary password found for employee ${employeeId}`);
      return null;
    }
    logger.error(`Failed to retrieve temporary password for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Delete temporary password from SSM (after employee sets new password)
 */
async function deleteTemporaryPassword(employeeId) {
  const parameterName = `/${CLUSTER_NAME}/workspaces/${employeeId}/temp-password`;
  
  try {
    const command = new DeleteParameterCommand({
      Name: parameterName
    });

    await ssmClient.send(command);
    logger.info(`Temporary password deleted from SSM for employee ${employeeId}`);
    return { success: true };
  } catch (error) {
    if (error.name === 'ParameterNotFound') {
      // Already deleted, that's fine
      return { success: true };
    }
    logger.error(`Failed to delete temporary password for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Store workspace metadata in SSM
 */
async function storeWorkspaceMetadata(workspace) {
  const parameterName = `/${CLUSTER_NAME}/workspaces/${workspace.employeeId}/metadata`;
  
  try {
    const metadata = {
      workspaceId: workspace.workspaceId,
      workspaceName: workspace.name,
      workspaceUrl: workspace.url,
      status: workspace.status,
      createdAt: workspace.createdAt,
      employeeId: workspace.employeeId
    };

    // First try to create with tags (new parameter)
    try {
      const createCommand = new PutParameterCommand({
        Name: parameterName,
        Value: JSON.stringify(metadata),
        Type: 'String',
        Description: `Workspace metadata for employee ${workspace.employeeId}`,
        Tags: [
          { Key: 'EmployeeID', Value: workspace.employeeId },
          { Key: 'WorkspaceID', Value: workspace.workspaceId },
          { Key: 'Type', Value: 'WorkspaceMetadata' }
        ]
      });
      await ssmClient.send(createCommand);
    } catch (createError) {
      // If parameter exists, update without tags
      if (createError.name === 'ParameterAlreadyExists') {
        const updateCommand = new PutParameterCommand({
          Name: parameterName,
          Value: JSON.stringify(metadata),
          Type: 'String',
          Description: `Workspace metadata for employee ${workspace.employeeId}`,
          Overwrite: true
        });
        await ssmClient.send(updateCommand);
      } else {
        throw createError;
      }
    }

    logger.info(`Workspace metadata stored in SSM for employee ${workspace.employeeId}`);
    return { success: true, parameterName };
  } catch (error) {
    logger.error(`Failed to store workspace metadata for ${workspace.employeeId}:`, error);
    throw error;
  }
}

/**
 * Get workspace metadata from SSM
 */
async function getWorkspaceMetadata(employeeId) {
  const parameterName = `/${CLUSTER_NAME}/workspaces/${employeeId}/metadata`;
  
  try {
    const command = new GetParameterCommand({
      Name: parameterName
    });

    const response = await ssmClient.send(command);
    return JSON.parse(response.Parameter.Value);
  } catch (error) {
    if (error.name === 'ParameterNotFound') {
      return null;
    }
    logger.error(`Failed to retrieve workspace metadata for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Get email configuration from SSM
 */
async function getEmailConfig() {
  const parameterName = `/${CLUSTER_NAME}/email/config`;
  
  try {
    // Force fresh parameter fetch without caching
    const command = new GetParameterCommand({
      Name: parameterName,
      WithDecryption: true
    });

    const response = await ssmClient.send(command);
    const config = JSON.parse(response.Parameter.Value);
    
    // Get workspace domain
    const domainParam = await ssmClient.send(new GetParameterCommand({
      Name: `/${CLUSTER_NAME}/workspaces/domain`
    }));
    
    config.workspace_domain = domainParam.Parameter.Value;
    
    return config;
  } catch (error) {
    logger.error('Failed to retrieve email configuration from SSM:', error);
    // Return defaults if SSM parameter doesn't exist
    return {
      sender_email: 'noreply@innovatech.com',
      sender_name: 'InnovaTech HR Portal',
      ses_region: AWS_REGION,
      workspace_domain: 'workspaces.innovatech.example.com'
    };
  }
}

// NOTE: Email templates are now stored in src/services/email.js
// SSM Parameter Store doesn't support {{}} template variables

/**
 * Store audit log entry in SSM
 */async function storeAuditLog(action, employeeId, metadata) {
  const timestamp = new Date().toISOString().replace(/:/g, '-').split('.')[0];
  const parameterName = `/${CLUSTER_NAME}/audit/${timestamp}/${action}-${employeeId}`;
  
  try {
    const auditEntry = {
      action,
      employeeId,
      timestamp: new Date().toISOString(),
      metadata
    };

    const command = new PutParameterCommand({
      Name: parameterName,
      Value: JSON.stringify(auditEntry),
      Type: 'String',
      Description: `Audit log: ${action} for employee ${employeeId}`,
      Tags: [
        { Key: 'Action', Value: action },
        { Key: 'EmployeeID', Value: employeeId },
        { Key: 'Type', Value: 'AuditLog' }
      ]
    });

    await ssmClient.send(command);
    logger.info(`Audit log stored: ${action} for employee ${employeeId}`);
    
    return { success: true };
  } catch (error) {
    // Don't fail the operation if audit logging fails
    logger.error(`Failed to store audit log for ${employeeId}:`, error);
    return { success: false, error: error.message };
  }
}

/**
 * Get all workspace parameters for an employee
 */
async function getEmployeeWorkspaceParameters(employeeId) {
  const path = `/${CLUSTER_NAME}/workspaces/${employeeId}`;
  
  try {
    const command = new GetParametersByPathCommand({
      Path: path,
      Recursive: true,
      WithDecryption: true
    });

    const response = await ssmClient.send(command);
    
    const parameters = {};
    response.Parameters.forEach(param => {
      const key = param.Name.split('/').pop();
      parameters[key] = param.Type === 'SecureString' ? '***ENCRYPTED***' : param.Value;
    });
    
    return parameters;
  } catch (error) {
    logger.error(`Failed to retrieve workspace parameters for ${employeeId}:`, error);
    throw error;
  }
}

module.exports = {
  storeTemporaryPassword,
  getTemporaryPassword,
  deleteTemporaryPassword,
  storeWorkspaceMetadata,
  getWorkspaceMetadata,
  getEmailConfig,
  storeAuditLog,
  getEmployeeWorkspaceParameters
};
