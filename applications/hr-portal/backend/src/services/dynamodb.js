const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { 
  DynamoDBDocumentClient, 
  PutCommand, 
  GetCommand, 
  UpdateCommand,
  DeleteCommand,
  ScanCommand,
  QueryCommand 
} = require('@aws-sdk/lib-dynamodb');
const logger = require('../utils/logger');

const client = new DynamoDBClient({ 
  region: process.env.AWS_REGION || 'eu-west-1'
});
const docClient = DynamoDBDocumentClient.from(client);

const EMPLOYEES_TABLE = process.env.DYNAMODB_TABLE || 'innovatech-employees';
const WORKSPACES_TABLE = process.env.DYNAMODB_WORKSPACES_TABLE || 'innovatech-employees-workspaces';

// Employee operations
async function createEmployee(employee) {
  const command = new PutCommand({
    TableName: EMPLOYEES_TABLE,
    Item: employee,
    ConditionExpression: 'attribute_not_exists(employeeId)'
  });

  try {
    await docClient.send(command);
    return employee;
  } catch (error) {
    logger.error('Error creating employee:', error);
    throw error;
  }
}

async function getEmployee(employeeId) {
  const command = new GetCommand({
    TableName: EMPLOYEES_TABLE,
    Key: { employeeId }
  });

  try {
    const response = await docClient.send(command);
    return response.Item;
  } catch (error) {
    logger.error('Error getting employee:', error);
    throw error;
  }
}

async function getEmployeeByEmail(email) {
  const command = new QueryCommand({
    TableName: EMPLOYEES_TABLE,
    IndexName: 'EmailIndex',
    KeyConditionExpression: 'email = :email',
    ExpressionAttributeValues: {
      ':email': email
    }
  });

  try {
    const response = await docClient.send(command);
    return response.Items && response.Items.length > 0 ? response.Items[0] : null;
  } catch (error) {
    logger.error('Error getting employee by email:', error);
    throw error;
  }
}

async function getAllEmployees(status = null) {
  if (status) {
    const command = new QueryCommand({
      TableName: EMPLOYEES_TABLE,
      IndexName: 'StatusIndex',
      KeyConditionExpression: '#status = :status',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': status
      }
    });

    try {
      const response = await docClient.send(command);
      return response.Items || [];
    } catch (error) {
      logger.error('Error querying employees by status:', error);
      throw error;
    }
  } else {
    const command = new ScanCommand({
      TableName: EMPLOYEES_TABLE
    });

    try {
      const response = await docClient.send(command);
      return response.Items || [];
    } catch (error) {
      logger.error('Error scanning employees:', error);
      throw error;
    }
  }
}

async function updateEmployee(employeeId, updates) {
  const updateExpression = [];
  const expressionAttributeNames = {};
  const expressionAttributeValues = {};

  Object.keys(updates).forEach((key, index) => {
    updateExpression.push(`#attr${index} = :val${index}`);
    expressionAttributeNames[`#attr${index}`] = key;
    expressionAttributeValues[`:val${index}`] = updates[key];
  });

  const command = new UpdateCommand({
    TableName: EMPLOYEES_TABLE,
    Key: { employeeId },
    UpdateExpression: `SET ${updateExpression.join(', ')}`,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: 'ALL_NEW'
  });

  try {
    const response = await docClient.send(command);
    return response.Attributes;
  } catch (error) {
    logger.error('Error updating employee:', error);
    throw error;
  }
}

// Workspace operations
async function createWorkspace(workspace) {
  const command = new PutCommand({
    TableName: WORKSPACES_TABLE,
    Item: workspace
  });

  try {
    await docClient.send(command);
    return workspace;
  } catch (error) {
    logger.error('Error creating workspace:', error);
    throw error;
  }
}

async function getWorkspaceByEmployee(employeeId) {
  const command = new QueryCommand({
    TableName: WORKSPACES_TABLE,
    IndexName: 'EmployeeIndex',
    KeyConditionExpression: 'employeeId = :employeeId',
    ExpressionAttributeValues: {
      ':employeeId': employeeId
    }
  });

  try {
    const response = await docClient.send(command);
    return response.Items && response.Items.length > 0 ? response.Items[0] : null;
  } catch (error) {
    logger.error('Error getting workspace by employee:', error);
    throw error;
  }
}

async function getAllWorkspaces() {
  const command = new ScanCommand({
    TableName: WORKSPACES_TABLE
  });

  try {
    const response = await docClient.send(command);
    return response.Items || [];
  } catch (error) {
    logger.error('Error scanning workspaces:', error);
    throw error;
  }
}

async function deleteWorkspace(workspaceId) {
  const command = new DeleteCommand({
    TableName: WORKSPACES_TABLE,
    Key: { workspaceId }
  });

  try {
    await docClient.send(command);
  } catch (error) {
    logger.error('Error deleting workspace:', error);
    throw error;
  }
}

async function updateWorkspace(workspaceId, updates) {
  // Build UpdateExpression dynamically
  const updateExpressions = [];
  const expressionAttributeNames = {};
  const expressionAttributeValues = {};
  
  Object.keys(updates).forEach((key, index) => {
    const attributeName = `#attr${index}`;
    const attributeValue = `:val${index}`;
    updateExpressions.push(`${attributeName} = ${attributeValue}`);
    expressionAttributeNames[attributeName] = key;
    expressionAttributeValues[attributeValue] = updates[key];
  });

  const command = new UpdateCommand({
    TableName: WORKSPACES_TABLE,
    Key: { workspaceId },
    UpdateExpression: `SET ${updateExpressions.join(', ')}`,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: 'ALL_NEW'
  });

  try {
    const response = await docClient.send(command);
    return response.Attributes;
  } catch (error) {
    logger.error('Error updating workspace:', error);
    throw error;
  }
}

module.exports = {
  createEmployee,
  getEmployee,
  getEmployeeByEmail,
  getAllEmployees,
  updateEmployee,
  createWorkspace,
  updateWorkspace,
  getWorkspaceByEmployee,
  getAllWorkspaces,
  deleteWorkspace
};
