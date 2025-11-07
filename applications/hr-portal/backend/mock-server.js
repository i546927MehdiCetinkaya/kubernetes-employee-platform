// Mock Backend Server voor Local Testing
// Simuleert de backend API zonder AWS dependencies

const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

// In-memory database (voor testing)
let employees = [
  {
    employeeId: '1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@company.com',
    role: 'developer',
    department: 'Engineering',
    status: 'active',
    createdAt: new Date().toISOString()
  },
  {
    employeeId: '2',
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane.smith@company.com',
    role: 'manager',
    department: 'Engineering',
    status: 'active',
    createdAt: new Date().toISOString()
  }
];

// Middleware
app.use(cors());
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Get all employees
app.get('/api/employees', (req, res) => {
  console.log(`Returning ${employees.length} employees`);
  res.json({ employees: employees });
});

// Get single employee
app.get('/api/employees/:id', (req, res) => {
  const employee = employees.find(e => e.employeeId === req.params.id);
  if (!employee) {
    return res.status(404).json({ error: 'Employee not found' });
  }
  res.json({ employee: employee });
});

// Create employee
app.post('/api/employees', (req, res) => {
  const { firstName, lastName, email, role, department } = req.body;
  
  // Validation
  if (!firstName || !lastName || !email) {
    return res.status(400).json({ 
      error: 'Missing required fields',
      message: 'firstName, lastName, and email are required' 
    });
  }

  const newEmployee = {
    employeeId: Date.now().toString(),
    firstName,
    lastName,
    email,
    role: role || 'developer',
    department: department || 'Engineering',
    status: 'active',
    createdAt: new Date().toISOString()
  };

  employees.push(newEmployee);
  console.log(`Created employee: ${firstName} ${lastName} (${newEmployee.employeeId})`);
  
  res.status(201).json({ 
    employee: newEmployee,
    message: 'Employee created successfully. Workspace provisioning in progress.'
  });
});

// Update employee
app.put('/api/employees/:id', (req, res) => {
  const index = employees.findIndex(e => e.employeeId === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Employee not found' });
  }

  employees[index] = {
    ...employees[index],
    ...req.body,
    employeeId: req.params.id, // Keep original ID
    updatedAt: new Date().toISOString()
  };

  console.log(`Updated employee: ${employees[index].firstName} ${employees[index].lastName}`);
  res.json({ 
    employee: employees[index],
    message: 'Employee updated successfully'
  });
});

// Delete employee
app.delete('/api/employees/:id', (req, res) => {
  const index = employees.findIndex(e => e.employeeId === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Employee not found' });
  }

  const deleted = employees.splice(index, 1)[0];
  console.log(`Deleted employee: ${deleted.firstName} ${deleted.lastName}`);
  
  res.json({ 
    message: 'Employee offboarded successfully. Workspace deprovisioning in progress.',
    employee: deleted 
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: err.message 
  });
});

// Start server
app.listen(PORT, () => {
  console.log('\n=================================');
  console.log('🚀 MOCK BACKEND SERVER STARTED');
  console.log('=================================');
  console.log(`URL: http://localhost:${PORT}`);
  console.log(`Health: http://localhost:${PORT}/health`);
  console.log(`Employees: http://localhost:${PORT}/api/employees`);
  console.log('\nInitial Data:');
  console.log(`  - ${employees.length} employees loaded`);
  console.log('\nThis is a MOCK server for local testing');
  console.log('No AWS credentials needed!');
  console.log('=================================\n');
});
