const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const dynamodbService = require('../services/dynamodb');
const workspaceService = require('../services/workspace');
const rbacService = require('../services/rbac');
const emailService = require('../services/email');
const logger = require('../utils/logger');

const router = express.Router();

// Get all employees (with RBAC filtering)
router.get('/', async (req, res, next) => {
  try {
    const currentEmployeeId = req.headers['x-employee-id'];
    
    if (!currentEmployeeId) {
      const { status } = req.query;
      const employees = await dynamodbService.getAllEmployees(status);
      return res.json({ employees });
    }

    // Get filtered employees based on RBAC
    const currentEmployee = await dynamodbService.getEmployee(currentEmployeeId);
    const employees = await rbacService.getEmployeesByDepartment(currentEmployee);
    
    res.json({ 
      employees,
      rbac: {
        role: currentEmployee.role,
        department: currentEmployee.department,
        permissions: rbacService.PERMISSIONS[currentEmployee.role]
      }
    });
  } catch (error) {
    next(error);
  }
});

// Get employee by ID (with RBAC check)
router.get('/:id', rbacService.requirePermission('employee', 'read'), async (req, res, next) => {
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

      await dynamodbService.createEmployee(employee);
      logger.info(`Employee created: ${employeeId}`);

      // Provision workspace and send email asynchronously
      workspaceService.provisionWorkspace(employee)
        .then(async workspace => {
          logger.info(`Workspace provisioned for employee ${employeeId}: ${workspace.workspaceId}`);
          
          // Generate temporary password for workspace
          const temporaryPassword = generateTemporaryPassword();
          
          // Send welcome email with credentials
          try {
            const emailResult = await emailService.sendWelcomeEmail(
              employee,
              workspace,
              temporaryPassword
            );
            logger.info(`Welcome email sent to ${employee.email}: ${emailResult.messageId}`);
          } catch (emailError) {
            logger.error(`Failed to send welcome email to ${employee.email}:`, emailError);
            // Don't fail the request if email fails - credentials still shown in UI
          }
        })
        .catch(error => {
          logger.error(`Failed to provision workspace for ${employeeId}:`, error);
        });

      res.status(201).json({ 
        employee,
        message: 'Employee created successfully. Workspace provisioning in progress. Welcome email will be sent shortly.'
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

    // Send termination notification email
    const terminationDate = new Date();
    terminationDate.setDate(terminationDate.getDate() + 7); // 7 days notice
    
    try {
      await emailService.sendWorkspaceTerminationEmail(
        employee,
        terminationDate.toLocaleDateString()
      );
      logger.info(`Termination email sent to ${employee.email}`);
    } catch (emailError) {
      logger.error(`Failed to send termination email to ${employee.email}:`, emailError);
      // Continue with deprovisioning even if email fails
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
    res.json({ message: 'Employee offboarded successfully. Termination email sent. Workspace deprovisioning in progress.' });
  } catch (error) {
    next(error);
  }
});

/**
 * Generate a secure temporary password
 */
function generateTemporaryPassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%';
  let password = '';
  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

module.exports = router;
