const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const dynamodbService = require('../services/dynamodb');
const workspaceService = require('../services/workspace');
const directoryService = require('../services/directory');
const logger = require('../utils/logger');

const router = express.Router();

// Get all employees
router.get('/', async (req, res, next) => {
  try {
    const { status } = req.query;
    const employees = await dynamodbService.getAllEmployees(status);
    res.json({ employees });
  } catch (error) {
    next(error);
  }
});

// Get employee by ID
router.get('/:id', async (req, res, next) => {
  try {
    const employee = await dynamodbService.getEmployee(req.params.id);
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }
    res.json({ employee });
  } catch (error) {
    next(error);
  }
});

// Get available IAM roles (department roles)
router.get('/roles/available', async (req, res, next) => {
  try {
    const roles = directoryService.getDepartmentRoles();
    res.json({ roles });
  } catch (error) {
    next(error);
  }
});

// Create new employee (Onboarding)
router.post('/',
  [
    body('firstName').notEmpty().trim(),
    body('lastName').notEmpty().trim(),
    body('email').isEmail().normalizeEmail(),
    body('role').isIn(['developer', 'manager', 'admin']),
    body('department').notEmpty().trim()
  ],
  async (req, res, next) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { firstName, lastName, email, role, department } = req.body;
      
      // Check if employee already exists
      const existing = await dynamodbService.getEmployeeByEmail(email);
      if (existing) {
        return res.status(409).json({ error: 'Employee with this email already exists' });
      }

      // Create employee record
      const employeeId = uuidv4();
      const employee = {
        employeeId,
        firstName,
        lastName,
        email,
        role,
        department,
        status: 'active',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      // Get assigned IAM role based on department
      const assignedIamRole = directoryService.getRoleForDepartment(department);
      employee.iamRole = assignedIamRole;

      await dynamodbService.createEmployee(employee);
      logger.info(`Employee created: ${employeeId} with IAM role: ${assignedIamRole}`);

      // Create Directory Service user (if enabled)
      let directoryUser = null;
      try {
        directoryUser = await directoryService.createDirectoryUser(employee);
        if (directoryUser.success) {
          logger.info(`Directory user created for ${employeeId}: ${directoryUser.username}`);
          employee.directoryUsername = directoryUser.username;
        }
      } catch (dirError) {
        logger.warn(`Directory user creation skipped for ${employeeId}:`, dirError.message);
      }

      // Provision workspace asynchronously
      workspaceService.provisionWorkspace(employee)
        .then(workspace => {
          logger.info(`Workspace provisioned for employee ${employeeId}: ${workspace.workspaceId}`);
        })
        .catch(error => {
          logger.error(`Failed to provision workspace for ${employeeId}:`, error);
        });

      res.status(201).json({ 
        employee,
        directoryUser: directoryUser?.success ? {
          username: directoryUser.username,
          domain: directoryUser.domain,
          iamRole: directoryUser.iamRole
        } : null,
        message: 'Employee created successfully. Workspace provisioning in progress.'
      });
    } catch (error) {
      next(error);
    }
  }
);

// Update employee
router.put('/:id',
  [
    body('firstName').optional().trim(),
    body('lastName').optional().trim(),
    body('role').optional().isIn(['developer', 'manager', 'admin']),
    body('department').optional().trim(),
    body('status').optional().isIn(['active', 'inactive', 'terminated'])
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const employee = await dynamodbService.getEmployee(req.params.id);
      if (!employee) {
        return res.status(404).json({ error: 'Employee not found' });
      }

      const updates = {
        ...req.body,
        updatedAt: new Date().toISOString()
      };

      // If department changed, update IAM role assignment
      if (req.body.department && req.body.department !== employee.department) {
        updates.iamRole = directoryService.getRoleForDepartment(req.body.department);
        logger.info(`Employee ${req.params.id} IAM role updated to: ${updates.iamRole}`);
      }

      await dynamodbService.updateEmployee(req.params.id, updates);
      logger.info(`Employee updated: ${req.params.id}`);

      res.json({ message: 'Employee updated successfully' });
    } catch (error) {
      next(error);
    }
  }
);

// Delete employee (Offboarding)
router.delete('/:id', async (req, res, next) => {
  try {
    const employee = await dynamodbService.getEmployee(req.params.id);
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    // Mark employee as terminated
    await dynamodbService.updateEmployee(req.params.id, {
      status: 'terminated',
      terminatedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });

    // Delete Directory Service user (if enabled)
    try {
      const result = await directoryService.deleteDirectoryUser(req.params.id);
      if (result.success) {
        logger.info(`Directory user deleted for employee ${req.params.id}`);
      }
    } catch (dirError) {
      logger.warn(`Directory user deletion skipped for ${req.params.id}:`, dirError.message);
    }

    // Deprovision workspace asynchronously
    workspaceService.deprovisionWorkspace(req.params.id)
      .then(() => {
        logger.info(`Workspace deprovisioned for employee ${req.params.id}`);
      })
      .catch(error => {
        logger.error(`Failed to deprovision workspace for ${req.params.id}:`, error);
      });

    logger.info(`Employee offboarded: ${req.params.id}`);
    res.json({ message: 'Employee offboarded successfully. Workspace deprovisioning in progress.' });
  } catch (error) {
    next(error);
  }
});

// Reset employee password
router.post('/:id/reset-password', async (req, res, next) => {
  try {
    const employee = await dynamodbService.getEmployee(req.params.id);
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const result = await directoryService.resetUserPassword(req.params.id);
    
    if (result.success) {
      res.json({
        message: 'Password reset successfully',
        username: result.username,
        tempPassword: result.tempPassword
      });
    } else {
      res.status(400).json({ error: result.reason || 'Failed to reset password' });
    }
  } catch (error) {
    next(error);
  }
});

module.exports = router;
