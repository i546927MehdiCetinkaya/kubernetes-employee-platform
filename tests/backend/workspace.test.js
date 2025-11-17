const workspaceService = require('../../applications/hr-portal/backend/src/services/workspace');
const dynamodbService = require('../../applications/hr-portal/backend/src/services/dynamodb');

jest.mock('../../applications/hr-portal/backend/src/services/dynamodb');
jest.mock('@kubernetes/client-node');

describe('Workspace Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('provisionWorkspace', () => {
    it('should create workspace record and provision pod', async () => {
      const employee = {
        employeeId: 'emp-123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        role: 'developer',
        department: 'Engineering'
      };

      dynamodbService.createWorkspace.mockResolvedValue({
        workspaceId: 'ws-123',
        employeeId: 'emp-123',
        status: 'provisioning'
      });

      const result = await workspaceService.provisionWorkspace(employee);

      expect(result.workspaceId).toBeDefined();
      expect(result.employeeId).toBe('emp-123');
      expect(dynamodbService.createWorkspace).toHaveBeenCalled();
    });

    it('should generate unique workspace id', async () => {
      const employee = {
        employeeId: 'emp-123',
        firstName: 'John',
        lastName: 'Doe',
        role: 'developer'
      };

      dynamodbService.createWorkspace.mockResolvedValue({
        workspaceId: expect.any(String)
      });

      const result1 = await workspaceService.provisionWorkspace(employee);
      const result2 = await workspaceService.provisionWorkspace(employee);

      expect(result1.workspaceId).not.toBe(result2.workspaceId);
    });

    it('should include RBAC configuration in workspace', async () => {
      const employee = {
        employeeId: 'emp-123',
        firstName: 'John',
        role: 'manager',
        department: 'Engineering'
      };

      dynamodbService.createWorkspace.mockResolvedValue({
        workspaceId: 'ws-123',
        rbac: {
          role: 'manager',
          department: 'Engineering'
        }
      });

      const result = await workspaceService.provisionWorkspace(employee);

      expect(result.rbac).toBeDefined();
      expect(result.rbac.role).toBe('manager');
    });
  });

  describe('deprovisionWorkspace', () => {
    it('should mark workspace as terminated', async () => {
      const employeeId = 'emp-123';

      dynamodbService.getWorkspaceByEmployee.mockResolvedValue({
        workspaceId: 'ws-123',
        employeeId: 'emp-123',
        status: 'active'
      });

      dynamodbService.updateWorkspace.mockResolvedValue({
        status: 'terminated'
      });

      await workspaceService.deprovisionWorkspace(employeeId);

      expect(dynamodbService.updateWorkspace).toHaveBeenCalledWith(
        'ws-123',
        expect.objectContaining({ status: 'terminated' })
      );
    });

    it('should handle missing workspace gracefully', async () => {
      dynamodbService.getWorkspaceByEmployee.mockResolvedValue(null);

      await expect(
        workspaceService.deprovisionWorkspace('nonexistent')
      ).resolves.not.toThrow();
    });
  });

  describe('getWorkspaceStatus', () => {
    it('should return workspace status', async () => {
      const workspaceId = 'ws-123';

      dynamodbService.getWorkspace.mockResolvedValue({
        workspaceId: 'ws-123',
        status: 'active',
        podName: 'john-doe-workspace'
      });

      const result = await workspaceService.getWorkspaceStatus(workspaceId);

      expect(result.status).toBe('active');
      expect(result.podName).toBeDefined();
    });

    it('should return null for nonexistent workspace', async () => {
      dynamodbService.getWorkspace.mockResolvedValue(null);

      const result = await workspaceService.getWorkspaceStatus('nonexistent');

      expect(result).toBeNull();
    });
  });
});
