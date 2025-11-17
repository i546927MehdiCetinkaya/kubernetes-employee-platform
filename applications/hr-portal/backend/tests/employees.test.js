const request = require('supertest');
const app = require('../src/index');
const dynamodbService = require('../src/services/dynamodb');
const workspaceService = require('../src/services/workspace');

// Mock AWS services
jest.mock('../src/services/dynamodb');
jest.mock('../src/services/workspace');

describe('Employee API Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/employees', () => {
    it('should return all employees when no employee-id header', async () => {
      const mockEmployees = [
        { employeeId: '1', firstName: 'John', lastName: 'Doe', role: 'developer' },
        { employeeId: '2', firstName: 'Jane', lastName: 'Smith', role: 'manager' }
      ];
      dynamodbService.getAllEmployees.mockResolvedValue(mockEmployees);

      const response = await request(app)
        .get('/api/employees')
        .expect(200);

      expect(response.body.employees).toEqual(mockEmployees);
      expect(dynamodbService.getAllEmployees).toHaveBeenCalled();
    });

    it('should return filtered employees based on RBAC when employee-id header present', async () => {
      const mockCurrentEmployee = {
        employeeId: 'manager-1',
        role: 'manager',
        department: 'Engineering'
      };
      const mockFilteredEmployees = [
        { employeeId: '1', department: 'Engineering' },
        { employeeId: '2', department: 'Engineering' }
      ];

      dynamodbService.getEmployee.mockResolvedValue(mockCurrentEmployee);
      dynamodbService.getAllEmployees.mockResolvedValue(mockFilteredEmployees);

      const response = await request(app)
        .get('/api/employees')
        .set('X-Employee-Id', 'manager-1')
        .expect(200);

      expect(response.body.rbac).toBeDefined();
      expect(response.body.rbac.role).toBe('manager');
    });
  });

  describe('GET /api/employees/:id', () => {
    it('should return employee by id', async () => {
      const mockEmployee = {
        employeeId: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        role: 'developer'
      };
      dynamodbService.getEmployee.mockResolvedValue(mockEmployee);

      const response = await request(app)
        .get('/api/employees/1')
        .expect(200);

      expect(response.body.employee).toEqual(mockEmployee);
    });

    it('should return 404 if employee not found', async () => {
      dynamodbService.getEmployee.mockResolvedValue(null);

      await request(app)
        .get('/api/employees/nonexistent')
        .expect(404);
    });
  });

  describe('POST /api/employees', () => {
    it('should create new employee and provision workspace', async () => {
      const newEmployee = {
        firstName: 'Alice',
        lastName: 'Johnson',
        email: 'alice@example.com',
        role: 'developer',
        department: 'Engineering'
      };

      dynamodbService.getEmployeeByEmail.mockResolvedValue(null);
      dynamodbService.createEmployee.mockResolvedValue({
        employeeId: 'new-id',
        ...newEmployee
      });
      workspaceService.provisionWorkspace.mockResolvedValue({
        workspaceId: 'ws-123',
        status: 'provisioning'
      });

      const response = await request(app)
        .post('/api/employees')
        .send(newEmployee)
        .expect(201);

      expect(response.body.employee).toBeDefined();
      expect(response.body.message).toContain('provisioning');
      expect(dynamodbService.createEmployee).toHaveBeenCalled();
    });

    it('should return 409 if employee email already exists', async () => {
      const existingEmployee = {
        employeeId: 'existing-id',
        email: 'existing@example.com'
      };

      dynamodbService.getEmployeeByEmail.mockResolvedValue(existingEmployee);

      await request(app)
        .post('/api/employees')
        .send({
          firstName: 'Test',
          lastName: 'User',
          email: 'existing@example.com',
          role: 'developer',
          department: 'Engineering'
        })
        .expect(409);
    });

    it('should return 400 for invalid data', async () => {
      await request(app)
        .post('/api/employees')
        .send({
          firstName: 'Test',
          // Missing required fields
        })
        .expect(400);
    });
  });

  describe('PUT /api/employees/:id', () => {
    it('should update employee', async () => {
      const mockEmployee = {
        employeeId: '1',
        firstName: 'John',
        role: 'developer'
      };

      dynamodbService.getEmployee.mockResolvedValue(mockEmployee);
      dynamodbService.updateEmployee.mockResolvedValue({ success: true });

      await request(app)
        .put('/api/employees/1')
        .send({ role: 'manager' })
        .expect(200);

      expect(dynamodbService.updateEmployee).toHaveBeenCalledWith(
        '1',
        expect.objectContaining({ role: 'manager' })
      );
    });

    it('should return 404 if employee not found', async () => {
      dynamodbService.getEmployee.mockResolvedValue(null);

      await request(app)
        .put('/api/employees/nonexistent')
        .send({ role: 'manager' })
        .expect(404);
    });
  });

  describe('DELETE /api/employees/:id', () => {
    it('should offboard employee and deprovision workspace', async () => {
      const mockEmployee = {
        employeeId: '1',
        firstName: 'John'
      };

      dynamodbService.getEmployee.mockResolvedValue(mockEmployee);
      dynamodbService.updateEmployee.mockResolvedValue({ success: true });
      workspaceService.deprovisionWorkspace.mockResolvedValue({ success: true });

      const response = await request(app)
        .delete('/api/employees/1')
        .expect(200);

      expect(response.body.message).toContain('offboarded');
      expect(dynamodbService.updateEmployee).toHaveBeenCalledWith(
        '1',
        expect.objectContaining({ status: 'terminated' })
      );
    });

    it('should return 404 if employee not found', async () => {
      dynamodbService.getEmployee.mockResolvedValue(null);

      await request(app)
        .delete('/api/employees/nonexistent')
        .expect(404);
    });
  });
});
