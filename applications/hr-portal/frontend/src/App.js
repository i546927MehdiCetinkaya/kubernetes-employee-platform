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
  Avatar,
  Menu,
  Divider,
  ListItemIcon,
  ListItemText,
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
  Logout as LogoutIcon,
  AccountCircle as AccountCircleIcon,
  Security as SecurityIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import Login from './auth/Login';
import ErrorBoundary from './components/ErrorBoundary';
import {
  isAuthenticated,
  getCurrentUser,
  signOut,
  hasPermission,
  getDisplayName,
  getUserGroups,
  getUserRole,
} from './auth/auth';
import { employees as employeesAPI, workspaces as workspacesAPI } from './api/api';

// Create Material-UI theme with dark mode
const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#1a1a1a',
      paper: '#2d2d2d',
    },
  },
});

function App() {
  const [user, setUser] = useState(null);
  const [authChecked, setAuthChecked] = useState(false);
  const [employees, setEmployees] = useState([]);
  const [workspaces, setWorkspaces] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const [activeTab, setActiveTab] = useState(0);
  const [newWorkspace, setNewWorkspace] = useState(null);
  const [userMenuAnchor, setUserMenuAnchor] = useState(null);

  // Form state
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    role: 'developer',
    department: 'Engineering',
  });

  // Check authentication on mount
  useEffect(() => {
    if (isAuthenticated()) {
      setUser(getCurrentUser());
    }
    setAuthChecked(true);
  }, []);

  // Fetch employees and workspaces when authenticated
  useEffect(() => {
    if (user) {
      fetchEmployees();
      fetchWorkspaces();
    }
  }, [user]);

  // Handle logout
  const handleLogout = () => {
    signOut();
    setUser(null);
    setEmployees([]);
    setWorkspaces([]);
  };

  // Handle successful login
  const handleLoginSuccess = (loggedInUser) => {
    setUser(loggedInUser);
  };

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
      const data = await employeesAPI.getAll();
      setEmployees(data.employees || []);
    } catch (err) {
      const message = err.code === 'PERMISSION_DENIED'
        ? 'You do not have permission to view employees. Contact your administrator.'
        : `Failed to fetch employees: ${err.message}`;
      setError(message);
      console.error('[App] Error fetching employees:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchWorkspaces = async () => {
    try {
      const data = await workspacesAPI.getAll();
      setWorkspaces(data.workspaces || []);
    } catch (err) {
      console.error('[App] Error fetching workspaces:', err);
      // Don't show error for workspaces - just log it
    }
  };

  // Track which employees are currently provisioning with status
  const [provisioningEmployees, setProvisioningEmployees] = useState(new Map());

  const handleProvisionWorkspace = async (employeeId) => {
    // Prevent double-click and duplicate provisioning
    if (provisioningEmployees.has(employeeId)) {
      setError('Workspace provisioning is already in progress for this employee.');
      return;
    }
    
    // Check if employee already has a workspace (frontend check)
    const existingWorkspace = getEmployeeWorkspace(employeeId);
    if (existingWorkspace) {
      setError('Employee already has an active workspace. Delete it first to create a new one.');
      return;
    }

    setProvisioningEmployees(prev => new Map(prev).set(employeeId, 'Starting provisioning...'));
    setError(null);
    setSuccess(null);
    
    // Start polling IMMEDIATELY to detect workspace as soon as it's created
    let pollAttempts = 0;
    const maxPollAttempts = 60; // 60 attempts * 5 seconds = 5 minutes max
    let pollInterval = null;
    
    const startPolling = () => {
      pollInterval = setInterval(async () => {
        pollAttempts++;
        
        try {
          // Refresh workspace list to check if workspace appears
          await fetchWorkspaces();
          
          // Check if workspace now exists in the list
          const updatedWorkspace = getEmployeeWorkspace(employeeId);
          
          if (updatedWorkspace) {
            // Workspace confirmed in list, safe to remove provisioning status
            clearInterval(pollInterval);
            setProvisioningEmployees(prev => {
              const newMap = new Map(prev);
              newMap.delete(employeeId);
              return newMap;
            });
            setSuccess(`✓ Workspace is ready! Access: ${updatedWorkspace.dnsName || updatedWorkspace.url}`);
          } else if (pollAttempts >= maxPollAttempts) {
            // Timeout after max attempts
            clearInterval(pollInterval);
            setProvisioningEmployees(prev => {
              const newMap = new Map(prev);
              newMap.delete(employeeId);
              return newMap;
            });
            setError('Workspace provisioning timed out. Please refresh the page to check status.');
          } else {
            // Update status message based on time elapsed
            const elapsed = pollAttempts * 5; // seconds
            if (elapsed > 120) {
              setProvisioningEmployees(prev => new Map(prev).set(employeeId, 'Finalizing workspace setup...'));
            } else if (elapsed > 60) {
              setProvisioningEmployees(prev => new Map(prev).set(employeeId, 'Configuring DNS record...'));
            } else {
              setProvisioningEmployees(prev => new Map(prev).set(employeeId, 'Creating Kubernetes pod and service...'));
            }
          }
        } catch (err) {
          console.error('Error polling workspace status:', err);
          // Continue polling even on error
        }
      }, 5000); // Poll every 5 seconds
    };
    
    // Start polling immediately
    startPolling();
    
    try {
      // Trigger backend provisioning (this will take 2-5 minutes)
      const response = await workspacesAPI.provision(employeeId);
      
      // Backend completed successfully
      console.log('[App] Backend provisioning completed:', response);
      
    } catch (err) {
      // Clear polling on error
      if (pollInterval) {
        clearInterval(pollInterval);
      }
      
      const errorMsg = err.code === 'PERMISSION_DENIED'
        ? 'You do not have permission to provision workspaces. Contact your administrator.'
        : `Failed to provision workspace: ${err.message}`;
      setError(`✗ ${errorMsg}`);
      console.error('[App] Error provisioning workspace:', err);
      
      // Remove from provisioning state immediately on error
      setProvisioningEmployees(prev => {
        const newMap = new Map(prev);
        newMap.delete(employeeId);
        return newMap;
      });
    }
  };

  const handleDeleteWorkspace = async (employeeId) => {
    // Check permission first
    if (!hasPermission('workspaces', 'delete')) {
      setError('You do not have permission to delete workspaces. Contact your administrator.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      await workspacesAPI.delete(employeeId);
      setSuccess('Workspace deleted successfully!');
      await fetchWorkspaces();
    } catch (err) {
      const message = err.code === 'PERMISSION_DENIED'
        ? 'You do not have permission to delete workspaces. Contact your administrator.'
        : `Failed to delete workspace: ${err.message}`;
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text) => {
    if (text) {
      navigator.clipboard.writeText(text);
      setSuccess('Copied to clipboard!');
    }
  };

  const getEmployeeName = (employeeId) => {
    const employee = employees.find(e => e.employeeId === employeeId);
    return employee ? `${employee.firstName} ${employee.lastName}` : 'Unknown';
  };

  const getEmployeeWorkspace = (employeeId) => {
    return workspaces.find(w => w.employeeId === employeeId);
  };
  
  // Get unique workspaces (one per employee)
  const getUniqueWorkspaces = () => {
    const seen = new Set();
    return workspaces.filter(w => {
      if (seen.has(w.employeeId)) return false;
      seen.add(w.employeeId);
      return true;
    });
  };

  const handleCreateEmployee = async () => {
    // Check permission first
    if (!hasPermission('employees', 'create')) {
      setError('You do not have permission to create employees. Contact your administrator.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      await employeesAPI.create(formData);
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
      const message = err.code === 'PERMISSION_DENIED'
        ? 'You do not have permission to create employees. Contact your administrator.'
        : `Failed to create employee: ${err.message}`;
      setError(message);
      console.error('[App] Error creating employee:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteEmployee = async (employeeId) => {
    // Check permission first
    if (!hasPermission('employees', 'delete')) {
      setError('You do not have permission to delete employees. Contact your administrator.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      await employeesAPI.delete(employeeId);
      setSuccess('Employee deleted successfully!');
      setDeleteConfirm(null);
      fetchEmployees();
    } catch (err) {
      const message = err.code === 'PERMISSION_DENIED'
        ? 'You do not have permission to delete employees. Contact your administrator.'
        : `Failed to delete employee: ${err.message}`;
      setError(message);
      console.error('[App] Error deleting employee:', err);
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

  // Show loading while checking auth
  if (!authChecked) {
    return (
      <ThemeProvider theme={theme}>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
          <CircularProgress />
        </Box>
      </ThemeProvider>
    );
  }

  // Show login if not authenticated
  if (!user) {
    return (
      <ThemeProvider theme={theme}>
        <Login onLoginSuccess={handleLoginSuccess} />
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <ErrorBoundary>
        <Box sx={{ flexGrow: 1 }}>
          {/* App Bar */}
          <AppBar position="static">
            <Toolbar>
              <PersonIcon sx={{ mr: 2 }} />
              <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                InnovaTech HR Portal
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                {/* User Profile Button */}
                <Button
                  color="inherit"
                  onClick={(e) => setUserMenuAnchor(e.currentTarget)}
                  endIcon={<ExpandMoreIcon />}
                  sx={{ textTransform: 'none' }}
                >
                  <Box sx={{ textAlign: 'right', mr: 1 }}>
                    <Typography variant="body2">{getDisplayName()}</Typography>
                    <Typography variant="caption" sx={{ opacity: 0.8 }}>
                      {getUserRole()}
                    </Typography>
                  </Box>
                  <Avatar sx={{ bgcolor: 'primary.dark' }}>
                    {getDisplayName().charAt(0).toUpperCase()}
                  </Avatar>
                </Button>

                {/* User Menu */}
                <Menu
                  anchorEl={userMenuAnchor}
                  open={Boolean(userMenuAnchor)}
                  onClose={() => setUserMenuAnchor(null)}
                  PaperProps={{
                    sx: { width: 300, mt: 1 }
                  }}
                >
                  {/* User Info */}
                  <Box sx={{ px: 2, py: 1.5 }}>
                    <Typography variant="subtitle1">{getDisplayName()}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {user?.email || user?.username}
                    </Typography>
                  </Box>
                  <Divider />

                  {/* User Groups */}
                  <Box sx={{ px: 2, py: 1.5 }}>
                    <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                      Groups
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                      {getUserGroups().length > 0 ? (
                        getUserGroups().map((group) => (
                          <Chip
                            key={group}
                            label={group}
                            size="small"
                            icon={<SecurityIcon />}
                            variant="outlined"
                          />
                        ))
                      ) : (
                        <Typography variant="body2" color="text.secondary">
                          No groups assigned
                        </Typography>
                      )}
                    </Box>
                  </Box>
                  <Divider />

                  {/* Logout */}
                  <MenuItem onClick={handleLogout}>
                    <ListItemIcon>
                      <LogoutIcon fontSize="small" />
                    </ListItemIcon>
                    <ListItemText>Logout</ListItemText>
                  </MenuItem>
                </Menu>
              </Box>
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
                    {hasPermission('employees', 'create') && (
                      <Button
                        variant="contained"
                        startIcon={<AddIcon />}
                        onClick={() => setOpenDialog(true)}
                        disabled={loading}
                      >
                        Add Employee
                      </Button>
                    )}
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
                                {hasPermission('employees', 'delete') && (
                                  <IconButton
                                    color="error"
                                    size="small"
                                    onClick={() => setDeleteConfirm(employee)}
                                  >
                                    <DeleteIcon />
                                  </IconButton>
                                )}
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
                              ) : provisioningEmployees.has(employee.employeeId) ? (
                                <Box sx={{ bgcolor: 'info.light', p: 2, borderRadius: 1 }}>
                                  <Box display="flex" alignItems="center" gap={1} mb={1}>
                                    <CircularProgress size={20} thickness={5} />
                                    <Typography variant="body2" color="info.dark" fontWeight="bold">
                                      Provisioning Workspace
                                    </Typography>
                                  </Box>
                                  <Typography variant="caption" color="info.dark" display="block" sx={{ pl: 3.5 }}>
                                    {provisioningEmployees.get(employee.employeeId)}
                                  </Typography>
                                  <Typography variant="caption" color="text.secondary" display="block" sx={{ pl: 3.5, mt: 0.5, fontWeight: 600 }}>
                                    ⏳ This takes 2-5 minutes. Please wait and do NOT click again!
                                  </Typography>
                                  <Typography variant="caption" color="text.secondary" display="block" sx={{ pl: 3.5, mt: 0.5, fontStyle: 'italic' }}>
                                    The button will automatically reappear when complete.
                                  </Typography>
                                </Box>
                              ) : hasPermission('workspaces', 'create') ? (
                                <Button
                                  fullWidth
                                  variant="contained"
                                  color="primary"
                                  startIcon={<ComputerIcon />}
                                  onClick={() => handleProvisionWorkspace(employee.employeeId)}
                                  disabled={loading || provisioningEmployees.size > 0 || provisioningEmployees.has(employee.employeeId)}
                                  sx={{
                                    pointerEvents: provisioningEmployees.size > 0 ? 'none' : 'auto'
                                  }}
                                >
                                  {provisioningEmployees.size > 0 && !provisioningEmployees.has(employee.employeeId) 
                                    ? 'Provisioning in progress...' 
                                    : 'Provision Workspace'}
                                </Button>
                              ) : (
                                <Tooltip title="You do not have permission to provision workspaces">
                                  <span>
                                    <Button
                                      fullWidth
                                      variant="outlined"
                                      disabled
                                      sx={{ opacity: 0.5 }}
                                    >
                                      Provision Workspace (No Permission)
                                    </Button>
                                  </span>
                                </Tooltip>
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
                      Active Linux Desktops: {getUniqueWorkspaces().length}
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
                {getUniqueWorkspaces().length === 0 ? (
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
                  getUniqueWorkspaces().map((workspace) => (
                    <Grid item xs={12} md={6} key={workspace.workspaceId}>
                      <Card elevation={3}>
                        <CardContent>
                          <Box display="flex" justifyContent="space-between" alignItems="start" mb={2}>
                            <Box>
                              <Typography variant="h6" gutterBottom>
                                <ComputerIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
                                {workspace.dnsName || workspace.name}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                Employee: {getEmployeeName(workspace.employeeId)}
                              </Typography>
                              {workspace.department && (
                                <Chip label={workspace.department} size="small" sx={{ mt: 0.5 }} />
                              )}
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
                            
                            {/* Personal DNS URL */}
                            {workspace.dnsName && (
                              <Box sx={{ mb: 1.5, p: 1, bgcolor: 'success.light', borderRadius: 1 }}>
                                <Typography variant="caption" color="success.dark" fontWeight="bold">
                                  Personal Workspace URL (VPN Required):
                                </Typography>
                                <Box display="flex" alignItems="center" gap={1}>
                                  <Typography variant="body2" fontWeight="bold" sx={{ wordBreak: 'break-all', flex: 1 }}>
                                    https://{workspace.dnsName}:{workspace.nodePort}
                                  </Typography>
                                  <Tooltip title="Copy URL">
                                    <IconButton size="small" onClick={() => copyToClipboard(`https://${workspace.dnsName}:${workspace.nodePort}`)}>
                                      <CopyIcon fontSize="small" />
                                    </IconButton>
                                  </Tooltip>
                                </Box>
                              </Box>
                            )}
                            
                            <Box sx={{ mb: 1 }}>
                              <Typography variant="caption" color="text.secondary">Direct URL:</Typography>
                              <Box display="flex" alignItems="center" gap={1}>
                                <Typography variant="body2" sx={{ wordBreak: 'break-all', flex: 1 }}>
                                  {workspace.url}
                                </Typography>
                                <Tooltip title="Copy URL">
                                  <IconButton size="small" onClick={() => copyToClipboard(workspace.url)}>
                                    <CopyIcon fontSize="small" />
                                  </IconButton>
                                </Tooltip>
                              </Box>
                            </Box>

                            <Box sx={{ mb: 1 }}>
                              <Typography variant="caption" color="text.secondary">Username:</Typography>
                              <Typography variant="body2" fontFamily="monospace" sx={{ bgcolor: 'white', px: 1, py: 0.5, borderRadius: 1, border: '1px solid #ddd', display: 'inline-block' }}>
                                {workspace.credentials?.username || 'N/A'}
                              </Typography>
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

                          <Alert severity="info" sx={{ mb: 2 }}>
                            Connect via VPN, then open the workspace URL in your browser.
                          </Alert>

                          <Box display="flex" gap={1}>
                            <Button
                              variant="contained"
                              color="primary"
                              startIcon={<OpenIcon />}
                              component={Link}
                              href={workspace.dnsName ? `https://${workspace.dnsName}:${workspace.nodePort}` : workspace.url}
                              target="_blank"
                              sx={{ flex: 1 }}
                            >
                              Open Desktop
                            </Button>
                            {hasPermission('workspaces', 'delete') && (
                              <Button
                                variant="outlined"
                                color="error"
                                startIcon={<DeleteIcon />}
                                onClick={() => handleDeleteWorkspace(workspace.employeeId)}
                                disabled={loading}
                              >
                                Delete
                              </Button>
                            )}
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
      </ErrorBoundary>
    </ThemeProvider>
  );
}

export default App;
