import React, { useEffect, useState, useCallback } from 'react';
import {
  Box,
  Typography,
  Button,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
  Alert,
  Snackbar,
  Paper,
  Stack,
} from '@mui/material';
import {
  DataGrid,
  GridColDef,
  GridRenderCellParams,
} from '@mui/x-data-grid';
import {
  Check as CheckIcon,
  Block as BlockIcon,
  Delete as DeleteIcon,
  Visibility as VisibilityIcon,
  Email as EmailIcon,
  CalendarToday as CalendarIcon,
  LocationOn as LocationIcon,
  Phone as PhoneIcon,
} from '@mui/icons-material';
import { getUsers, verifyCharity, updateUserStatus, deleteUser } from '../../services/api';
import { User } from '../../types';

export const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [detailsDialogOpen, setDetailsDialogOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const showError = (message: string) => {
    setError(message);
    setTimeout(() => setError(null), 5000);
  };

  const showSuccess = (message: string) => {
    setSuccessMessage(message);
    setTimeout(() => setSuccessMessage(null), 5000);
  };

  const fetchUsers = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getUsers();
      console.log('Fetched users:', data); // Debug log
      setUsers(data.filter(user => user.role !== 'admin'));
    } catch (error) {
      console.error('Error fetching users:', error);
      showError('Failed to fetch users. Please try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const interval = setInterval(fetchUsers, 30000); // Refresh every 30 seconds
    return () => clearInterval(interval);
  }, [fetchUsers]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleVerifyCharity = async (userId: string) => {
    try {
      const updatedUser = await verifyCharity(userId);
      console.log('Verified charity response:', updatedUser); // Debug log
      showSuccess('Charity verified successfully');
      await fetchUsers(); // Refresh immediately after verification
    } catch (error) {
      console.error('Error verifying charity:', error);
      showError('Failed to verify charity. Please try again.');
    }
  };

  const handleUpdateStatus = async (userId: string, newStatus: User['status']) => {
    try {
      const updatedUser = await updateUserStatus(userId, newStatus);
      console.log('Updated user status response:', updatedUser); // Debug log
      showSuccess(`User status updated to ${newStatus}`);
      await fetchUsers(); // Refresh immediately after status update
    } catch (error) {
      console.error('Error updating user status:', error);
      showError('Failed to update user status. Please try again.');
    }
  };

  const handleDeleteUser = async () => {
    if (!selectedUser) return;

    try {
      await deleteUser(selectedUser._id);
      showSuccess('User deleted successfully');
      setDeleteDialogOpen(false);
      setSelectedUser(null);
      await fetchUsers(); // Refresh immediately after deletion
    } catch (error) {
      console.error('Error deleting user:', error);
      showError('Failed to delete user. Please try again.');
    }
  };

  const columns: GridColDef<User>[] = [
    { field: 'name', headerName: 'Name', flex: 1 },
    { field: 'email', headerName: 'Email', flex: 1 },
    {
      field: 'role',
      headerName: 'Role',
      width: 120,
      renderCell: (params: GridRenderCellParams<User>) => (
        <Chip
          label={params.row.role}
          color={
            params.row.role === 'admin'
              ? 'error'
              : params.row.role === 'charity'
              ? 'primary'
              : 'default'
          }
          size="small"
        />
      ),
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params: GridRenderCellParams<User>) => (
        <Chip
          label={params.row.status}
          color={
            params.row.status === 'verified'
              ? 'success'
              : params.row.status === 'rejected'
              ? 'error'
              : 'warning'
          }
          size="small"
        />
      ),
    },
    {
      field: 'isVerified',
      headerName: 'Verified',
      width: 100,
      renderCell: (params: GridRenderCellParams<User>) => (
        <Chip
          label={params.row.isVerified ? 'Yes' : 'No'}
          color={params.row.isVerified ? 'success' : 'default'}
          size="small"
        />
      ),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 200,
      renderCell: (params: GridRenderCellParams<User>) => (
        <Box>
          <IconButton
            color="info"
            onClick={() => {
              setSelectedUser(params.row);
              setDetailsDialogOpen(true);
            }}
            size="small"
            title="View Details"
          >
            <VisibilityIcon />
          </IconButton>
          {/* Only show verify button for unverified charity users */}
          {params.row.role === 'charity' && !params.row.isVerified && (
            <IconButton
              color="primary"
              onClick={() => handleVerifyCharity(params.row._id)}
              size="small"
              title="Verify Charity"
            >
              <CheckIcon />
            </IconButton>
          )}
          {/* Only show status update button for unverified charity users */}
          {params.row.role === 'charity' && !params.row.isVerified && params.row.status !== 'rejected' && (
            <IconButton
              color={params.row.status === 'verified' ? 'error' : 'success'}
              onClick={() =>
                handleUpdateStatus(
                  params.row._id,
                  params.row.status === 'verified' ? 'rejected' : 'verified'
                )
              }
              size="small"
              title={params.row.status === 'verified' ? 'Reject User' : 'Verify User'}
            >
              <BlockIcon />
            </IconButton>
          )}
          <IconButton
            color="error"
            onClick={() => {
              setSelectedUser(params.row);
              setDeleteDialogOpen(true);
            }}
            size="small"
            title="Delete User"
          >
            <DeleteIcon />
          </IconButton>
        </Box>
      ),
    },
  ];

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        User Management
      </Typography>

      <Snackbar 
        open={error !== null} 
        autoHideDuration={5000} 
        onClose={() => setError(null)}
      >
        <Alert severity="error" onClose={() => setError(null)}>
          {error}
        </Alert>
      </Snackbar>

      <Snackbar 
        open={successMessage !== null} 
        autoHideDuration={5000} 
        onClose={() => setSuccessMessage(null)}
      >
        <Alert severity="success" onClose={() => setSuccessMessage(null)}>
          {successMessage}
        </Alert>
      </Snackbar>

      <Box sx={{ height: 'calc(100vh - 200px)', width: '100%' }}>
        <DataGrid<User>
          rows={users}
          columns={columns}
          getRowId={(row) => row._id}
          loading={loading}
          disableRowSelectionOnClick
          pageSizeOptions={[10, 25, 50]}
          initialState={{
            pagination: { paginationModel: { pageSize: 10 } },
          }}
        />
      </Box>

      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete the user "{selectedUser?.name}"? This action cannot
            be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDeleteUser} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog 
        open={detailsDialogOpen} 
        onClose={() => setDetailsDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>User Details</DialogTitle>
        <DialogContent>
          {selectedUser && (
            <Stack spacing={2} sx={{ mt: 1 }}>
              <Paper sx={{ p: 2 }}>
                <Stack spacing={2}>
                  <Box>
                    <Typography variant="subtitle2" color="textSecondary">Name</Typography>
                    <Typography variant="body1">{selectedUser.name}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="subtitle2" color="textSecondary" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <EmailIcon fontSize="small" /> Email
                    </Typography>
                    <Typography variant="body1">{selectedUser.email}</Typography>
                  </Box>
                  {selectedUser.phone && (
                    <Box>
                      <Typography variant="subtitle2" color="textSecondary" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <PhoneIcon fontSize="small" /> Phone
                      </Typography>
                      <Typography variant="body1">{selectedUser.phone}</Typography>
                    </Box>
                  )}
                  {selectedUser.address && (
                    <Box>
                      <Typography variant="subtitle2" color="textSecondary" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <LocationIcon fontSize="small" /> Address
                      </Typography>
                      <Typography variant="body1">
                        {(() => {
                          if (typeof selectedUser.address === 'string') {
                            return selectedUser.address;
                          }
                          const addressObj = selectedUser.address as { street: string; city: string; state: string; zipCode: string; };
                          return `${addressObj.street}, ${addressObj.city}, ${addressObj.state} ${addressObj.zipCode}`;
                        })()}
                      </Typography>
                    </Box>
                  )}
                </Stack>
              </Paper>

              <Paper sx={{ p: 2 }}>
                <Stack spacing={2}>
                  <Box>
                    <Typography variant="subtitle2" color="textSecondary">Role</Typography>
                    <Chip
                      label={selectedUser.role}
                      color={
                        selectedUser.role === 'admin'
                          ? 'error'
                          : selectedUser.role === 'charity'
                          ? 'primary'
                          : 'default'
                      }
                      size="small"
                    />
                  </Box>
                  <Box>
                    <Typography variant="subtitle2" color="textSecondary">Status</Typography>
                    <Chip
                      label={selectedUser.status}
                      color={
                        selectedUser.status === 'verified'
                          ? 'success'
                          : selectedUser.status === 'rejected'
                          ? 'error'
                          : 'warning'
                      }
                      size="small"
                    />
                  </Box>
                  <Box>
                    <Typography variant="subtitle2" color="textSecondary">Verified</Typography>
                    <Chip
                      label={selectedUser.isVerified ? 'Yes' : 'No'}
                      color={selectedUser.isVerified ? 'success' : 'default'}
                      size="small"
                    />
                  </Box>
                </Stack>
              </Paper>

              {selectedUser.role === 'charity' && (
                <Paper sx={{ p: 2 }}>
                  <Typography variant="subtitle1" gutterBottom>Charity Details</Typography>
                  <Stack spacing={2}>
                    {selectedUser.registrationNumber && (
                      <Box>
                        <Typography variant="subtitle2" color="textSecondary">Registration Number</Typography>
                        <Typography variant="body1">{selectedUser.registrationNumber}</Typography>
                      </Box>
                    )}
                    {selectedUser.description && (
                      <Box>
                        <Typography variant="subtitle2" color="textSecondary">Description</Typography>
                        <Typography variant="body1">{selectedUser.description}</Typography>
                      </Box>
                    )}
                  </Stack>
                </Paper>
              )}

              <Paper sx={{ p: 2 }}>
                <Stack spacing={2}>
                  <Box>
                    <Typography variant="subtitle2" color="textSecondary" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <CalendarIcon fontSize="small" /> Created At
                    </Typography>
                    <Typography variant="body1">
                      {new Date(selectedUser.createdAt).toLocaleString()}
                    </Typography>
                  </Box>
                  {selectedUser.updatedAt && (
                    <Box>
                      <Typography variant="subtitle2" color="textSecondary" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <CalendarIcon fontSize="small" /> Last Updated
                      </Typography>
                      <Typography variant="body1">
                        {new Date(selectedUser.updatedAt).toLocaleString()}
                      </Typography>
                    </Box>
                  )}
                </Stack>
              </Paper>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailsDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}; 