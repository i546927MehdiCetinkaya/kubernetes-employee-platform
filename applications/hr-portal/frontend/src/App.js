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
  Tabs,
  Tab,
  Link,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
  Work as WorkIcon,
  Computer as ComputerIcon,
  ContentCopy as CopyIcon,
  OpenInNew as OpenIcon,
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

// API configuration - use same origin (LoadBalancer handles routing)
const API_BASE_URL = process.env.REACT_APP_API_URL || window.location.origin;

function App() {
  const [employees, setEmployees] = useState([]);
  const [workspaces, setWorkspaces] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const [activeTab, setActiveTab] = useState(0);
  const [newWorkspace, setNewWorkspace] = useState(null);

  // Form state
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    role: 'developer',
    department: 'Engineering',
  });

  // Fetch employees and workspaces on component mount
  useEffect(() => {
    fetchEmployees();
    fetchWorkspaces();
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

  const fetchWorkspaces = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/workspaces`);
      setWorkspaces(response.data.workspaces || []);
    } catch (err) {
      console.error('Error fetching workspaces:', err);
    }
  };

  const handleProvisionWorkspace = async (employeeId) => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.post(`${API_BASE_URL}/api/workspaces/provision/${employeeId}`);
      const workspace = response.data.workspace;
      setNewWorkspace(workspace);
      setSuccess(`Workspace provisioned successfully!`);
      fetchWorkspaces();
    } catch (err) {
      setError(`Failed to provision workspace: ${err.response?.data?.error || err.message}`);
      console.error('Error provisioning workspace:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteWorkspace = async (employeeId) => {
    setLoading(true);
    setError(null);
    try {
      await axios.delete(`${API_BASE_URL}/api/workspaces/${employeeId}`);
      setSuccess('Workspace deleted successfully!');
      fetchWorkspaces();
    } catch (err) {
      setError(`Failed to delete workspace: ${err.response?.data?.error || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    setSuccess('Copied to clipboard!');
  };

  const getEmployeeName = (employeeId) => {
    const employee = employees.find(e => e.employeeId === employeeId);
    return employee ? `${employee.firstName} ${employee.lastName}` : 'Unknown';
  };

  const getEmployeeWorkspace = (employeeId) => {
    return workspaces.find(w => w.employeeId === employeeId);
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

          {/* Tabs */}
          <Paper elevation={2} sx={{ mb: 3 }}>
            <Tabs value={activeTab} onChange={(e, v) => setActiveTab(v)}>
              <Tab icon={<PersonIcon />} label="Employees" />
              <Tab icon={<ComputerIcon />} label="Workspaces" />
            </Tabs>
          </Paper>

          {/* Employees Tab */}
          {activeTab === 0 && (
            <>
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
                      onClick={() => { fetchEmployees(); fetchWorkspaces(); }}
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
                    employees.map((employee) => {
                      const workspace = getEmployeeWorkspace(employee.employeeId);
                      return (
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

                              <Box sx={{ bgcolor: 'grey.100', p: 1.5, borderRadius: 1, mb: 2 }}>
                                <Typography variant="caption" color="text.secondary" display="block">
                                  <WorkIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />
                                  {employee.department}
                                </Typography>
                              </Box>

                              {/* Workspace Section */}
                              {workspace ? (
                                <Box sx={{ bgcolor: 'success.light', p: 1.5, borderRadius: 1 }}>
                                  <Typography variant="caption" color="success.dark" fontWeight="bold" display="block">
                                    <ComputerIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />
                                    Workspace Active
                                  </Typography>
                                  <Button
                                    size="small"
                                    variant="outlined"
                                    color="success"
                                    sx={{ mt: 1 }}
                                    onClick={() => setActiveTab(1)}
                                  >
                                    View Credentials
                                  </Button>
                                </Box>
                              ) : (
                                <Button
                                  fullWidth
                                  variant="contained"
                                  color="primary"
                                  startIcon={<ComputerIcon />}
                                  onClick={() => handleProvisionWorkspace(employee.employeeId)}
                                  disabled={loading}
                                >
                                  Provision Workspace
                                </Button>
                              )}
                            </CardContent>
                          </Card>
                        </Grid>
                      );
                    })
                  )}
                </Grid>
              )}
            </>
          )}

          {/* Workspaces Tab */}
          {activeTab === 1 && (
            <>
              <Paper elevation={2} sx={{ p: 3, mb: 3 }}>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Box>
                    <Typography variant="h4" gutterBottom>
                      Workspaces
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Active Linux Desktops: {workspaces.length}
                    </Typography>
                  </Box>
                  <Button
                    variant="outlined"
                    startIcon={<RefreshIcon />}
                    onClick={fetchWorkspaces}
                    disabled={loading}
                  >
                    Refresh
                  </Button>
                </Box>
              </Paper>

              <Grid container spacing={3}>
                {workspaces.length === 0 ? (
                  <Grid item xs={12}>
                    <Paper sx={{ p: 4, textAlign: 'center' }}>
                      <ComputerIcon sx={{ fontSize: 60, color: 'text.secondary', mb: 2 }} />
                      <Typography variant="h6" color="text.secondary">
                        No workspaces found
                      </Typography>
                      <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                        Provision a workspace from the Employees tab
                      </Typography>
                    </Paper>
                  </Grid>
                ) : (
                  workspaces.map((workspace) => (
                    <Grid item xs={12} md={6} key={workspace.workspaceId}>
                      <Card elevation={3}>
                        <CardContent>
                          <Box display="flex" justifyContent="space-between" alignItems="start" mb={2}>
                            <Box>
                              <Typography variant="h6" gutterBottom>
                                <ComputerIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
                                {workspace.name}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                Employee: {getEmployeeName(workspace.employeeId)}
                              </Typography>
                            </Box>
                            <Chip
                              label={workspace.status}
                              color={workspace.status === 'provisioning' ? 'warning' : 'success'}
                              size="small"
                            />
                          </Box>

                          {/* Credentials Box */}
                          <Paper sx={{ p: 2, bgcolor: 'grey.100', mb: 2 }}>
                            <Typography variant="subtitle2" gutterBottom fontWeight="bold">
                              🔐 Login Credentials
                            </Typography>
                            
                            <Box sx={{ mb: 1 }}>
                              <Typography variant="caption" color="text.secondary">URL:</Typography>
                              <Box display="flex" alignItems="center" gap={1}>
                                <Typography variant="body2" sx={{ wordBreak: 'break-all', flex: 1 }}>
                                  {workspace.url}/vnc.html
                                </Typography>
                                <Tooltip title="Copy URL">
                                  <IconButton size="small" onClick={() => copyToClipboard(`${workspace.url}/vnc.html`)}>
                                    <CopyIcon fontSize="small" />
                                  </IconButton>
                                </Tooltip>
                                <Tooltip title="Open in new tab">
                                  <IconButton size="small" component={Link} href={`${workspace.url}/vnc.html`} target="_blank">
                                    <OpenIcon fontSize="small" />
                                  </IconButton>
                                </Tooltip>
                              </Box>
                            </Box>

                            <Box>
                              <Typography variant="caption" color="text.secondary">Password:</Typography>
                              <Box display="flex" alignItems="center" gap={1}>
                                <Typography variant="body2" fontFamily="monospace" sx={{ 
                                  bgcolor: 'white', 
                                  px: 1, 
                                  py: 0.5, 
                                  borderRadius: 1,
                                  border: '1px solid #ddd'
                                }}>
                                  {workspace.credentials?.password || 'N/A'}
                                </Typography>
                                <Tooltip title="Copy Password">
                                  <IconButton size="small" onClick={() => copyToClipboard(workspace.credentials?.password)}>
                                    <CopyIcon fontSize="small" />
                                  </IconButton>
                                </Tooltip>
                              </Box>
                            </Box>
                          </Paper>

                          <Box display="flex" gap={1}>
                            <Button
                              variant="contained"
                              color="primary"
                              startIcon={<OpenIcon />}
                              component={Link}
                              href={`${workspace.url}/vnc.html`}
                              target="_blank"
                              sx={{ flex: 1 }}
                            >
                              Open Desktop
                            </Button>
                            <Button
                              variant="outlined"
                              color="error"
                              startIcon={<DeleteIcon />}
                              onClick={() => handleDeleteWorkspace(workspace.employeeId)}
                            >
                              Delete
                            </Button>
                          </Box>
                        </CardContent>
                      </Card>
                    </Grid>
                  ))
                )}
              </Grid>
            </>
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

        {/* New Workspace Credentials Dialog */}
        <Dialog
          open={Boolean(newWorkspace)}
          onClose={() => setNewWorkspace(null)}
          maxWidth="sm"
          fullWidth
        >
          <DialogTitle sx={{ bgcolor: 'success.main', color: 'white' }}>
            🎉 Workspace Created Successfully!
          </DialogTitle>
          <DialogContent sx={{ mt: 2 }}>
            <Alert severity="info" sx={{ mb: 2 }}>
              Save these credentials! The password cannot be retrieved later.
            </Alert>
            
            <Paper sx={{ p: 2, bgcolor: 'grey.100', mb: 2 }}>
              <Typography variant="subtitle2" gutterBottom fontWeight="bold">
                Workspace: {newWorkspace?.name}
              </Typography>
              
              <Box sx={{ mb: 2 }}>
                <Typography variant="caption" color="text.secondary">Desktop URL:</Typography>
                <Box display="flex" alignItems="center" gap={1}>
                  <TextField
                    fullWidth
                    size="small"
                    value={`${newWorkspace?.url}/vnc.html`}
                    InputProps={{ readOnly: true }}
                  />
                  <Tooltip title="Copy">
                    <IconButton onClick={() => copyToClipboard(`${newWorkspace?.url}/vnc.html`)}>
                      <CopyIcon />
                    </IconButton>
                  </Tooltip>
                </Box>
              </Box>

              <Box>
                <Typography variant="caption" color="text.secondary">Password:</Typography>
                <Box display="flex" alignItems="center" gap={1}>
                  <TextField
                    fullWidth
                    size="small"
                    value={newWorkspace?.credentials?.password || ''}
                    InputProps={{ 
                      readOnly: true,
                      sx: { fontFamily: 'monospace', fontWeight: 'bold' }
                    }}
                  />
                  <Tooltip title="Copy">
                    <IconButton onClick={() => copyToClipboard(newWorkspace?.credentials?.password)}>
                      <CopyIcon />
                    </IconButton>
                  </Tooltip>
                </Box>
              </Box>
            </Paper>

            <Typography variant="body2" color="text.secondary">
              Note: The workspace may take 1-2 minutes to fully start. Click "Open Desktop" to connect.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setNewWorkspace(null)}>Close</Button>
            <Button
              variant="contained"
              color="primary"
              startIcon={<OpenIcon />}
              component={Link}
              href={`${newWorkspace?.url}/vnc.html`}
              target="_blank"
              onClick={() => setNewWorkspace(null)}
            >
              Open Desktop
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </ThemeProvider>
  );
}

export default App;
