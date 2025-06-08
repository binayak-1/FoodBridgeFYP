import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import {
  DataGrid,
  GridColDef,
  GridRenderCellParams,
  GridRowParams,
  GridActionsCellItem,
} from '@mui/x-data-grid';
import {
  Delete as DeleteIcon,
  Edit as EditIcon,
} from '@mui/icons-material';
import { getDonations, updateDonationStatus, deleteDonation } from '../../services/api';
import { Donation } from '../../types';
import { format } from 'date-fns';

export const DonationManagement: React.FC = () => {
  const [donations, setDonations] = useState<Donation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedDonation, setSelectedDonation] = useState<Donation | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [statusDialogOpen, setStatusDialogOpen] = useState(false);
  const [selectedStatus, setSelectedStatus] = useState<Donation['status']>('pending');
  const [filterStatus, setFilterStatus] = useState<Donation['status'] | 'all'>('all');

  const fetchDonations = React.useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('Fetching donations with status:', filterStatus);
      const data = await getDonations(filterStatus === 'all' ? undefined : filterStatus);
      console.log('Raw donations data:', data);
      
      if (!Array.isArray(data)) {
        console.error('Received non-array data:', data);
        setError('Invalid data format received from server');
        setDonations([]);
        return;
      }

      const validatedData = data.filter((donation): donation is Donation => {
        if (!donation || typeof donation !== 'object') {
          console.error('Invalid donation entry:', donation);
          return false;
        }

        console.log('Processing donation:', donation);

        const requiredFields = ['_id', 'title', 'status', 'expiryDate'] as const;
        const missingFields = requiredFields.filter(field => !donation[field]);
        if (missingFields.length > 0) {
          console.error(`Donation missing required fields: ${missingFields.join(', ')}`, donation);
          return false;
        }

        return true;
      });

      console.log('Final validated donations:', validatedData);
      setDonations(validatedData);
    } catch (error) {
      console.error('Error fetching donations:', error);
      setError(error instanceof Error ? error.message : 'Failed to fetch donations');
      setDonations([]);
    } finally {
      setLoading(false);
    }
  }, [filterStatus]);

  useEffect(() => {
    fetchDonations();
  }, [fetchDonations]);

  const handleUpdateStatus = async () => {
    if (!selectedDonation) return;

    try {
      await updateDonationStatus(selectedDonation._id, selectedStatus);
      setStatusDialogOpen(false);
      setSelectedDonation(null);
      await fetchDonations();
    } catch (error) {
      console.error('Error updating donation status:', error);
    }
  };

  const handleDeleteDonation = async () => {
    if (!selectedDonation) return;

    try {
      await deleteDonation(selectedDonation._id);
      setDeleteDialogOpen(false);
      setSelectedDonation(null);
      await fetchDonations();
    } catch (error) {
      console.error('Error deleting donation:', error);
    }
  };

  const getStatusColor = (status: string): "default" | "primary" | "secondary" | "error" | "info" | "success" | "warning" => {
    switch (status) {
      case 'pending':
        return 'warning';
      case 'available':
        return 'info';
      case 'accepted':
        return 'primary';
      case 'completed':
        return 'success';
      case 'expired':
        return 'error';
      default:
        return 'default';
    }
  };

  const columns: GridColDef<Donation>[] = [
    { 
      field: 'title', 
      headerName: 'Title', 
      flex: 1,
      renderCell: (params: GridRenderCellParams<Donation>) => {
        const donation = params.row;
        return <Typography>{donation.title}</Typography>;
      }
    },
    {
      field: 'donor',
      headerName: 'Donor',
      width: 200,
      renderCell: (params: GridRenderCellParams<Donation>) => (
        <Typography>
          {params.row.donor?.name || 'Unknown Donor'}
        </Typography>
      ),
    },
    {
      field: 'charity',
      headerName: 'Charity',
      width: 200,
      renderCell: (params: GridRenderCellParams<Donation>) => (
        <Typography>
          {params.row.charity?.name || 'Not Accepted'}
        </Typography>
      ),
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params: GridRenderCellParams<Donation>) => (
        <Chip
          label={params.row.status}
          color={getStatusColor(params.row.status)}
          size="small"
        />
      ),
    },
    {
      field: 'foodType',
      headerName: 'Food Type',
      width: 120,
      renderCell: (params: GridRenderCellParams<Donation>) => (
        <Typography>{params.row.foodType}</Typography>
      )
    },
    {
      field: 'quantity',
      headerName: 'Quantity',
      width: 120,
      renderCell: (params: GridRenderCellParams<Donation>) => (
        <Typography>
          {`${params.row.quantity} ${params.row.quantityUnit}`}
        </Typography>
      )
    },
    {
      field: 'expiryDate',
      headerName: 'Expiry Date',
      width: 150,
      renderCell: (params: GridRenderCellParams<Donation>) => {
        try {
          return (
            <Typography>
              {format(new Date(params.row.expiryDate), 'MMM d, yyyy')}
            </Typography>
          );
        } catch (error) {
          console.error('Error formatting expiry date:', error);
          return <Typography>Invalid Date</Typography>;
        }
      }
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      type: 'actions',
      getActions: (params: GridRowParams<Donation>) => [
        <GridActionsCellItem
          key="edit"
          icon={<EditIcon color="primary" />}
          label="Edit"
          onClick={() => {
            setSelectedDonation(params.row);
            setSelectedStatus(params.row.status);
            setStatusDialogOpen(true);
          }}
        />,
        <GridActionsCellItem
          key="delete"
          icon={<DeleteIcon sx={{ color: 'error.main' }} />}
          label="Delete"
          onClick={() => {
            setSelectedDonation(params.row);
            setDeleteDialogOpen(true);
          }}
        />,
      ],
    },
  ];

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Donation Management</Typography>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Filter by Status</InputLabel>
          <Select
            value={filterStatus}
            label="Filter by Status"
            onChange={(e) => setFilterStatus(e.target.value as typeof filterStatus)}
          >
            <MenuItem value="all">All Status</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="available">Available</MenuItem>
            <MenuItem value="accepted">Accepted</MenuItem>
            <MenuItem value="completed">Completed</MenuItem>
            <MenuItem value="expired">Expired</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {error && (
        <Box sx={{ mb: 2, p: 2, backgroundColor: '#ffebee', borderRadius: 1 }}>
          <Typography color="error" variant="body1">
            {error}
          </Typography>
          <Button
            sx={{ mt: 1 }}
            size="small"
            variant="outlined"
            color="error"
            onClick={() => fetchDonations()}
          >
            Retry
          </Button>
        </Box>
      )}

      <Box sx={{ height: 'calc(100vh - 200px)', width: '100%' }}>
        <DataGrid
          rows={donations}
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

      <Dialog open={statusDialogOpen} onClose={() => setStatusDialogOpen(false)}>
        <DialogTitle>Update Donation Status</DialogTitle>
        <DialogContent>
          <FormControl fullWidth sx={{ mt: 2 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={selectedStatus}
              label="Status"
              onChange={(e) => setSelectedStatus(e.target.value as Donation['status'])}
            >
              <MenuItem value="pending">Pending</MenuItem>
              <MenuItem value="available">Available</MenuItem>
              <MenuItem value="accepted">Accepted</MenuItem>
              <MenuItem value="completed">Completed</MenuItem>
              <MenuItem value="expired">Expired</MenuItem>
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setStatusDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleUpdateStatus} color="primary" variant="contained">
            Update
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete the donation "{selectedDonation?.title}"? This
            action cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDeleteDonation} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}; 