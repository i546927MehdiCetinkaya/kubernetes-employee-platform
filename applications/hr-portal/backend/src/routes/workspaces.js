const express = require('express');
const workspaceService = require('../services/workspace');
const dynamodbService = require('../services/dynamodb');

const router = express.Router();

// Debug endpoint to test K8s connectivity
router.get('/debug/k8s', async (req, res) => {
  try {
    const k8s = require('@kubernetes/client-node');
    const kc = new k8s.KubeConfig();
    
    let config = 'none';
    let error = null;
    
    try {
      kc.loadFromCluster();
      config = 'in-cluster';
    } catch (e1) {
      try {
        kc.loadFromDefault();
        config = 'default';
      } catch (e2) {
        error = `in-cluster: ${e1.message}, default: ${e2.message}`;
      }
    }
    
    if (config !== 'none') {
      const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
      try {
        const namespaces = await k8sApi.listNamespace();
        res.json({
          status: 'connected',
          config,
          namespaceCount: namespaces.body.items.length,
          namespaces: namespaces.body.items.map(n => n.metadata.name)
        });
      } catch (apiError) {
        res.json({
          status: 'config-loaded',
          config,
          apiError: apiError.message
        });
      }
    } else {
      res.json({
        status: 'no-config',
        error
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message, stack: error.stack });
  }
});

// Get all workspaces
router.get('/', async (req, res, next) => {
  try {
    const workspaces = await dynamodbService.getAllWorkspaces();
    res.json({ workspaces });
  } catch (error) {
    next(error);
  }
});

// Get workspace by employee ID
router.get('/employee/:employeeId', async (req, res, next) => {
  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(req.params.employeeId);
    if (!workspace) {
      return res.status(404).json({ error: 'Workspace not found' });
    }
    res.json({ workspace });
  } catch (error) {
    next(error);
  }
});

// Get workspace status
router.get('/:workspaceId/status', async (req, res, next) => {
  try {
    const status = await workspaceService.getWorkspaceStatus(req.params.workspaceId);
    res.json({ status });
  } catch (error) {
    next(error);
  }
});

// Manually provision workspace
router.post('/provision/:employeeId', async (req, res, next) => {
  try {
    const employee = await dynamodbService.getEmployee(req.params.employeeId);
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const workspace = await workspaceService.provisionWorkspace(employee);
    res.status(201).json({ workspace });
  } catch (error) {
    console.error('Provision error:', error);
    res.status(500).json({ 
      error: error.message, 
      stack: error.stack,
      name: error.name 
    });
  }
});

// Manually deprovision workspace
router.delete('/:employeeId', async (req, res, next) => {
  try {
    await workspaceService.deprovisionWorkspace(req.params.employeeId);
    res.json({ message: 'Workspace deprovisioned successfully' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
