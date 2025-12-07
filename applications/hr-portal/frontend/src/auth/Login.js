import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
  Container,
  Chip,
} from '@mui/material';
import { Lock as LockIcon, Info as InfoIcon } from '@mui/icons-material';
import { auth as authAPI } from '../api/api';
import { signIn } from './auth';

function Login({ onLoginSuccess }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [authHealth, setAuthHealth] = useState(null);

  // Check auth health on mount
  React.useEffect(() => {
    const checkHealth = async () => {
      try {
        const health = await authAPI.health();
        setAuthHealth(health);
      } catch (err) {
        console.warn('[Login] Could not check auth health:', err);
      }
    };
    checkHealth();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await authAPI.login(username, password);

      // Store token and user info using auth utility
      signIn(response.token, response.user);

      onLoginSuccess(response.user);
    } catch (err) {
      console.error('[Login] Login error:', err);
      setError(err.message || 'An error occurred during login.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Card sx={{ width: '100%', maxWidth: 400 }}>
          <CardContent sx={{ p: 4 }}>
            <Box sx={{ textAlign: 'center', mb: 3 }}>
              <LockIcon sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
              <Typography variant="h5" component="h1" gutterBottom>
                InnovaTech HR Portal
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Sign in to manage employee lifecycle
              </Typography>

              {/* Auth Health Status */}
              {authHealth && (
                <Box sx={{ mt: 2, display: 'flex', gap: 1, justifyContent: 'center', flexWrap: 'wrap' }}>
                  <Chip
                    icon={<InfoIcon />}
                    label={authHealth.ldap?.healthy ? 'AD: Connected' : 'AD: Fallback Mode'}
                    color={authHealth.ldap?.healthy ? 'success' : 'warning'}
                    size="small"
                    variant="outlined"
                  />
                  {authHealth.fallback?.enabled && (
                    <Chip
                      icon={<InfoIcon />}
                      label="Emergency Access: Available"
                      color="info"
                      size="small"
                      variant="outlined"
                    />
                  )}
                </Box>
              )}
            </Box>

            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            <form onSubmit={handleSubmit}>
              <TextField
                fullWidth
                label="Username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                margin="normal"
                required
                autoComplete="username"
                autoFocus
                placeholder="firstname.lastname"
              />
              <TextField
                fullWidth
                label="Password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                margin="normal"
                required
                autoComplete="current-password"
              />
              <Button
                fullWidth
                type="submit"
                variant="contained"
                size="large"
                disabled={loading}
                sx={{ mt: 3, mb: 2 }}
              >
                {loading ? <CircularProgress size={24} /> : 'Sign In'}
              </Button>
            </form>

            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', textAlign: 'center', mt: 2 }}>
              Protected by Zero Trust Security • Active Directory Integration
            </Typography>
          </CardContent>
        </Card>
      </Box>
    </Container>
  );
}

export default Login;
