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
    let clusterInfo = null;
    
    try {
      kc.loadFromCluster();
      config = 'in-cluster';
      clusterInfo = {
        cluster: kc.getCurrentCluster(),
        user: kc.getCurrentUser()
      };
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
        // Get pods with full status
        const pods = await k8sApi.listNamespacedPod('workspaces');
        const podDetails = pods.body.items.map(p => ({
          name: p.metadata.name,
          phase: p.status.phase,
          conditions: p.status.conditions,
          containerStatuses: p.status.containerStatuses
        }));
        
        // Get services with LoadBalancer info
        const services = await k8sApi.listNamespacedService('workspaces');
        const serviceDetails = services.body.items.map(s => ({
          name: s.metadata.name,
          type: s.spec.type,
          loadBalancer: s.status.loadBalancer,
          ports: s.spec.ports
        }));
        
        res.json({
          status: 'connected',
          config,
          podCount: pods.body.items.length,
          pods: podDetails,
          services: serviceDetails
        });
      } catch (apiError) {
        res.json({
          status: 'config-loaded',
          config,
          clusterInfo,
          apiError: apiError.message,
          apiErrorBody: apiError.body,
          apiErrorStatusCode: apiError.statusCode
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
      name: error.name,
      statusCode: error.statusCode,
      body: error.body
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

// Force cleanup a workspace by name (debug)
router.delete('/debug/cleanup/:name', async (req, res) => {
  try {
    const k8s = require('@kubernetes/client-node');
    const kc = new k8s.KubeConfig();
    kc.loadFromCluster();
    const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
    
    const name = req.params.name;
    const results = [];
    
    // Delete pod
    try {
      await k8sApi.deleteNamespacedPod(name, 'workspaces');
      results.push(`Pod ${name} deleted`);
    } catch (e) { results.push(`Pod: ${e.message}`); }
    
    // Delete service
    try {
      await k8sApi.deleteNamespacedService(name, 'workspaces');
      results.push(`Service ${name} deleted`);
    } catch (e) { results.push(`Service: ${e.message}`); }
    
    // Delete secret
    try {
      await k8sApi.deleteNamespacedSecret(`${name}-secret`, 'workspaces');
      results.push(`Secret ${name}-secret deleted`);
    } catch (e) { results.push(`Secret: ${e.message}`); }
    
    // Delete PVC
    try {
      await k8sApi.deleteNamespacedPersistentVolumeClaim(`${name}-pvc`, 'workspaces');
      results.push(`PVC ${name}-pvc deleted`);
    } catch (e) { results.push(`PVC: ${e.message}`); }
    
    res.json({ results });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Sync DynamoDB with K8s - remove stale entries
router.post('/debug/sync', async (req, res) => {
  try {
    const k8s = require('@kubernetes/client-node');
    const kc = new k8s.KubeConfig();
    kc.loadFromCluster();
    const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
    
    // Get running pods
    const pods = await k8sApi.listNamespacedPod('workspaces');
    const runningPodNames = new Set(pods.body.items.map(p => p.metadata.name));
    
    // Get services with LoadBalancer URLs
    const services = await k8sApi.listNamespacedService('workspaces');
    const serviceUrls = {};
    for (const svc of services.body.items) {
      if (svc.status.loadBalancer && svc.status.loadBalancer.ingress && svc.status.loadBalancer.ingress[0]) {
        const hostname = svc.status.loadBalancer.ingress[0].hostname;
        serviceUrls[svc.metadata.name] = `http://${hostname}`;
      }
    }
    
    // Get all workspaces from DynamoDB
    const workspaces = await dynamodbService.getAllWorkspaces();
    
    const results = {
      checked: workspaces.length,
      deleted: [],
      kept: [],
      updated: []
    };
    
    // Group workspaces by employeeId
    const byEmployee = {};
    for (const ws of workspaces) {
      if (!byEmployee[ws.employeeId]) {
        byEmployee[ws.employeeId] = [];
      }
      byEmployee[ws.employeeId].push(ws);
    }
    
    // For each employee, keep only the workspace that matches a running service
    for (const employeeId of Object.keys(byEmployee)) {
      const employeeWorkspaces = byEmployee[employeeId];
      let foundMatch = false;
      
      for (const ws of employeeWorkspaces) {
        // Check if this workspace URL matches a running service
        const serviceUrl = serviceUrls[ws.name];
        const urlMatches = serviceUrl && ws.url && ws.url.includes(serviceUrl.split('://')[1].split('.')[0]);
        
        if (runningPodNames.has(ws.name) && !foundMatch) {
          // First matching workspace for this employee - keep it
          foundMatch = true;
          if (ws.status !== 'active') {
            // Also update the URL to the current service URL if available
            const updates = { status: 'active' };
            if (serviceUrl) {
              updates.url = serviceUrl;
            }
            await dynamodbService.updateWorkspace(ws.workspaceId, updates);
            results.updated.push({ name: ws.name, workspaceId: ws.workspaceId });
          }
          results.kept.push({ name: ws.name, workspaceId: ws.workspaceId });
        } else {
          // Either pod doesn't exist, or we already kept one for this employee
          await dynamodbService.deleteWorkspace(ws.workspaceId);
          results.deleted.push({ name: ws.name, workspaceId: ws.workspaceId, reason: foundMatch ? 'duplicate' : 'no-pod' });
        }
      }
    }
    
    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message, stack: error.stack });
  }
});

// Delete workspace by workspaceId from DynamoDB only
router.delete('/debug/db/:workspaceId', async (req, res) => {
  try {
    await dynamodbService.deleteWorkspace(req.params.workspaceId);
    res.json({ message: 'Deleted from DynamoDB' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
