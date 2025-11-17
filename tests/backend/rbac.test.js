const rbacService = require('../../applications/hr-portal/backend/src/services/rbac');
const dynamodbService = require('../../applications/hr-portal/backend/src/services/dynamodb');

jest.mock('../../applications/hr-portal/backend/src/services/dynamodb');

describe('RBAC Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Permission Checks', () => {
    it('admin should have access to all departments', async () => {
      const adminEmployee = {
        employeeId: 'admin-1',
        role: 'admin',
        department: 'IT'
      };

      const targetEmployee = {
        employeeId: 'emp-1',
        department: 'Sales'
      };

      dynamodbService.getEmployee
        .mockResolvedValueOnce(adminEmployee)
        .mockResolvedValueOnce(targetEmployee);

      const result = await rbacService.checkPermission(
        'admin-1',
        'read',
        'employee',
        'emp-1'
      );

      expect(result.allowed).toBe(true);
    });

    it('manager should have access to own department only', async () => {
      const managerEmployee = {
        employeeId: 'manager-1',
        role: 'manager',
        department: 'Engineering'
      };

      const sameDepEmployee = {
        employeeId: 'emp-1',
        department: 'Engineering'
      };

      dynamodbService.getEmployee
        .mockResolvedValueOnce(managerEmployee)
        .mockResolvedValueOnce(sameDepEmployee);

      const result = await rbacService.checkPermission(
        'manager-1',
        'read',
        'employee',
        'emp-1'
      );

      expect(result.allowed).toBe(true);
    });

    it('manager should not have access to other departments', async () => {
      const managerEmployee = {
        employeeId: 'manager-1',
        role: 'manager',
        department: 'Engineering'
      };

      const otherDepEmployee = {
        employeeId: 'emp-1',
        department: 'Sales'
      };

      dynamodbService.getEmployee
        .mockResolvedValueOnce(managerEmployee)
        .mockResolvedValueOnce(otherDepEmployee);

      const result = await rbacService.checkPermission(
        'manager-1',
        'write',
        'employee',
        'emp-1'
      );

      expect(result.allowed).toBe(false);
      expect(result.reason).toContain('different department');
    });

    it('developer should not have access to employee management', async () => {
      const developerEmployee = {
        employeeId: 'dev-1',
        role: 'developer',
        department: 'Engineering'
      };

      dynamodbService.getEmployee.mockResolvedValue(developerEmployee);

      const result = await rbacService.checkPermission(
        'dev-1',
        'read',
        'employee',
        'emp-1'
      );

      expect(result.allowed).toBe(false);
    });

    it('manager should not have delete permissions', async () => {
      const managerEmployee = {
        employeeId: 'manager-1',
        role: 'manager',
        department: 'Engineering'
      };

      dynamodbService.getEmployee.mockResolvedValue(managerEmployee);

      const result = await rbacService.checkPermission(
        'manager-1',
        'delete',
        'employee',
        'emp-1'
      );

      expect(result.allowed).toBe(false);
      expect(result.reason).toContain('not allowed');
    });
  });

  describe('Department Filtering', () => {
    it('should return all departments for admin', () => {
      const adminEmployee = {
        role: 'admin',
        department: 'IT'
      };

      const departments = rbacService.getAllowedDepartments(adminEmployee);
      expect(departments).toEqual(['all']);
    });

    it('should return own department for manager', () => {
      const managerEmployee = {
        role: 'manager',
        department: 'Engineering'
      };

      const departments = rbacService.getAllowedDepartments(managerEmployee);
      expect(departments).toEqual(['Engineering']);
    });

    it('should return own department for developer', () => {
      const developerEmployee = {
        role: 'developer',
        department: 'Engineering'
      };

      const departments = rbacService.getAllowedDepartments(developerEmployee);
      expect(departments).toEqual(['Engineering']);
    });
  });

  describe('RBAC Middleware', () => {
    it('should pass request if permission granted', async () => {
      const req = {
        headers: {
          'x-employee-id': 'admin-1'
        },
        params: { id: 'emp-1' }
      };
      const res = {};
      const next = jest.fn();

      dynamodbService.getEmployee.mockResolvedValue({
        employeeId: 'admin-1',
        role: 'admin'
      });

      const middleware = rbacService.requirePermission('employee', 'read');
      await middleware(req, res, next);

      expect(next).toHaveBeenCalledWith();
    });

    it('should return 403 if permission denied', async () => {
      const req = {
        headers: {
          'x-employee-id': 'dev-1'
        },
        params: { id: 'emp-1' }
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      dynamodbService.getEmployee.mockResolvedValue({
        employeeId: 'dev-1',
        role: 'developer'
      });

      const middleware = rbacService.requirePermission('employee', 'read');
      await middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });
  });
});
