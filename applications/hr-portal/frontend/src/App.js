import React, { useState, useEffect } from 'react';
import {
  Container,
  AppBar,
  Toolbar,
  Typography,
  Box,
  Button,
  Card,
  CardContent,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  IconButton,
  Chip,
  Alert,
  CircularProgress,
  Grid,
  Paper,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
  Work as WorkIcon,
} from '@mui/icons-material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import axios from 'axios';

// Create Material-UI theme
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

// API configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

function App() {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);

  // Form state
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    role: 'developer',
    department: 'Engineering',
  });

  // Fetch employees on component mount
  useEffect(() => {
    fetchEmployees();
  }, []);

  // Auto-hide alerts after 5 seconds
  useEffect(() => {
    if (error || success) {
      const timer = setTimeout(() => {
        setError(null);
        setSuccess(null);
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [error, success]);

  const fetchEmployees = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.get(`${API_BASE_URL}/api/employees`);
      setEmployees(response.data.employees || []);
    } catch (err) {
      setError(`Failed to fetch employees: ${err.message}`);
      console.error('Error fetching employees:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateEmployee = async () => {
    setLoading(true);
    setError(null);
    try {
      await axios.post(`${API_BASE_URL}/api/employees`, formData);
      setSuccess(`Employee ${formData.firstName} ${formData.lastName} created successfully!`);
      setOpenDialog(false);
      setFormData({
        firstName: '',
        lastName: '',
        email: '',
        role: 'developer',
        department: 'Engineering',
      });
      fetchEmployees();
    } catch (err) {
      setError(`Failed to create employee: ${err.response?.data?.message || err.message}`);
      console.error('Error creating employee:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteEmployee = async (employeeId) => {
    setLoading(true);
    setError(null);
    try {
      await axios.delete(`${API_BASE_URL}/api/employees/${employeeId}`);
      setSuccess('Employee deleted successfully!');
      setDeleteConfirm(null);
      fetchEmployees();
    } catch (err) {
      setError(`Failed to delete employee: ${err.response?.data?.message || err.message}`);
      console.error('Error deleting employee:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const getRoleColor = (role) => {
    const colors = {
      developer: 'primary',
      manager: 'secondary',
      admin: 'warning',
    };
    return colors[role] || 'default';
  };

  const getStatusColor = (status) => {
    return status === 'active' ? 'success' : 'default';
  };

  return (
    <ThemeProvider theme={theme}>
      <Box sx={{ flexGrow: 1 }}>
        {/* App Bar */}
        <AppBar position="static">
          <Toolbar>
            <PersonIcon sx={{ mr: 2 }} />
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              InnovaTech HR Portal
            </Typography>
            <Typography variant="body2">
              Employee Lifecycle Management
            </Typography>
          </Toolbar>
        </AppBar>

        {/* Main Content */}
        <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
          {/* Alerts */}
          {error && (
            <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}
          {success && (
            <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
              {success}
            </Alert>
          )}

          {/* Header with actions */}
          <Paper elevation={2} sx={{ p: 3, mb: 3 }}>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Box>
                <Typography variant="h4" gutterBottom>
                  Employees
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Total: {employees.length} employees
                </Typography>
              </Box>
              <Box>
                <Button
                  variant="outlined"
                  startIcon={<RefreshIcon />}
                  onClick={fetchEmployees}
                  sx={{ mr: 2 }}
                  disabled={loading}
                >
                  Refresh
                </Button>
                <Button
                  variant="contained"
                  startIcon={<AddIcon />}
                  onClick={() => setOpenDialog(true)}
                  disabled={loading}
                >
                  Add Employee
                </Button>
              </Box>
            </Box>
          </Paper>

          {/* Loading state */}
          {loading && (
            <Box display="flex" justifyContent="center" my={4}>
              <CircularProgress />
            </Box>
          )}

          {/* Employees Grid */}
          {!loading && (
            <Grid container spacing={3}>
              {employees.length === 0 ? (
                <Grid item xs={12}>
                  <Paper sx={{ p: 4, textAlign: 'center' }}>
                    <PersonIcon sx={{ fontSize: 60, color: 'text.secondary', mb: 2 }} />
                    <Typography variant="h6" color="text.secondary">
                      No employees found
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                      Click "Add Employee" to create your first employee
                    </Typography>
                  </Paper>
                </Grid>
              ) : (
                employees.map((employee) => (
                  <Grid item xs={12} md={6} lg={4} key={employee.employeeId}>
                    <Card elevation={3}>
                      <CardContent>
                        <Box display="flex" justifyContent="space-between" alignItems="start" mb={2}>
                          <Box>
                            <Typography variant="h6" gutterBottom>
                              {employee.firstName} {employee.lastName}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" gutterBottom>
                              {employee.email}
                            </Typography>
                          </Box>
                          <IconButton
                            color="error"
                            size="small"
                            onClick={() => setDeleteConfirm(employee)}
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Box>
                        
                        <Box display="flex" gap={1} mb={2}>
                          <Chip
                            label={employee.role}
                            color={getRoleColor(employee.role)}
                            size="small"
                          />
                          <Chip
                            label={employee.status}
                            color={getStatusColor(employee.status)}
                            size="small"
                          />
                        </Box>

                        <Box sx={{ bgcolor: 'grey.100', p: 1.5, borderRadius: 1 }}>
                          <Typography variant="caption" color="text.secondary" display="block">
                            <WorkIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />
                            {employee.department}
                          </Typography>
                          <Typography variant="caption" color="text.secondary" display="block" mt={0.5}>
                            ID: {employee.employeeId}
                          </Typography>
                          {employee.workspaceUrl && (
                            <Typography variant="caption" color="primary" display="block" mt={0.5}>
                              Workspace: {employee.workspaceUrl}
                            </Typography>
                          )}
                        </Box>
                      </CardContent>
                    </Card>
                  </Grid>
                ))
              )}
            </Grid>
          )}
        </Container>

        {/* Create Employee Dialog */}
        <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
          <DialogTitle>Add New Employee</DialogTitle>
          <DialogContent>
            <Box sx={{ mt: 2 }}>
              <TextField
                fullWidth
                label="First Name"
                name="firstName"
                value={formData.firstName}
                onChange={handleInputChange}
                margin="normal"
                required
              />
              <TextField
                fullWidth
                label="Last Name"
                name="lastName"
                value={formData.lastName}
                onChange={handleInputChange}
                margin="normal"
                required
              />
              <TextField
                fullWidth
                label="Email"
                name="email"
                type="email"
                value={formData.email}
                onChange={handleInputChange}
                margin="normal"
                required
              />
              <FormControl fullWidth margin="normal">
                <InputLabel>Role</InputLabel>
                <Select
                  name="role"
                  value={formData.role}
                  onChange={handleInputChange}
                  label="Role"
                >
                  <MenuItem value="developer">Developer</MenuItem>
                  <MenuItem value="manager">Manager</MenuItem>
                  <MenuItem value="admin">Admin</MenuItem>
                </Select>
              </FormControl>
              <FormControl fullWidth margin="normal">
                <InputLabel>Department</InputLabel>
                <Select
                  name="department"
                  value={formData.department}
                  onChange={handleInputChange}
                  label="Department"
                >
                  <MenuItem value="Engineering">Engineering</MenuItem>
                  <MenuItem value="Human Resources">Human Resources</MenuItem>
                  <MenuItem value="Sales">Sales</MenuItem>
                  <MenuItem value="Marketing">Marketing</MenuItem>
                  <MenuItem value="Operations">Operations</MenuItem>
                </Select>
              </FormControl>
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
            <Button
              onClick={handleCreateEmployee}
              variant="contained"
              disabled={loading || !formData.firstName || !formData.lastName || !formData.email}
            >
              Create Employee
            </Button>
          </DialogActions>
        </Dialog>

        {/* Delete Confirmation Dialog */}
        <Dialog
          open={Boolean(deleteConfirm)}
          onClose={() => setDeleteConfirm(null)}
        >
          <DialogTitle>Confirm Delete</DialogTitle>
          <DialogContent>
            <Typography>
              Are you sure you want to delete employee{' '}
              <strong>
                {deleteConfirm?.firstName} {deleteConfirm?.lastName}
              </strong>
              ?
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              This will mark the employee as terminated and trigger workspace deprovisioning.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDeleteConfirm(null)}>Cancel</Button>
            <Button
              onClick={() => handleDeleteEmployee(deleteConfirm.employeeId)}
              color="error"
              variant="contained"
              disabled={loading}
            >
              Delete
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </ThemeProvider>
  );
}

export default App;
