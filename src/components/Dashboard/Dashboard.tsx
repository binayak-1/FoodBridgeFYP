import React, { useEffect, useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  CircularProgress,
} from '@mui/material';
import {
  BarChart,
  PieChart,
} from '@mui/x-charts';
import { getDashboardStats } from '../../services/api';
import { DashboardStats } from '../../types';

export const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const data = await getDashboardStats();
        setStats(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch dashboard stats');
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <Typography color="error">{error}</Typography>
      </Box>
    );
  }

  if (!stats) {
    return null;
  }

  const statCards = [
    { title: 'Total Users', value: stats.totalUsers ?? 0 },
    { title: 'Total Donors', value: stats.totalDonors ?? 0 },
    { title: 'Total Charities', value: stats.totalCharities ?? 0 },
    { title: 'Pending Verifications', value: stats.pendingVerifications ?? 0 },
    { title: 'Active Donations', value: stats.activeDonations ?? 0 },
    { title: 'Completed Donations', value: stats.completedDonations ?? 0 },
  ];

  // Transform monthly donations data to match the chart requirements
  const monthlyDonationsData = (stats.monthlyDonations ?? []).map((item) => ({
    month: item.month,
    donations: item.count,
  }));

  // Transform donations by type data to match the chart requirements
  const donationsByTypeData = (stats.donationsByType ?? []).map((item) => ({
    id: item.type,
    value: item.count,
    label: item.type,
  }));

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>

      <Box 
        sx={{ 
          display: 'grid',
          gridTemplateColumns: {
            xs: '1fr',
            sm: 'repeat(2, 1fr)',
            md: 'repeat(3, 1fr)'
          },
          gap: 3,
          mb: 4
        }}
      >
        {statCards.map((stat) => (
          <Card key={stat.title}>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                {stat.title}
              </Typography>
              <Typography variant="h4">{stat.value}</Typography>
            </CardContent>
          </Card>
        ))}
      </Box>

      <Box 
        sx={{ 
          display: 'grid',
          gridTemplateColumns: {
            xs: '1fr',
            md: '2fr 1fr'
          },
          gap: 3
        }}
      >
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Monthly Donations
            </Typography>
            <Box height={300}>
              {monthlyDonationsData.length > 0 ? (
                <BarChart
                  dataset={monthlyDonationsData}
                  xAxis={[{ scaleType: 'band', dataKey: 'month' }]}
                  series={[{ dataKey: 'donations', label: 'Donations' }]}
                  height={300}
                />
              ) : (
                <Box 
                  display="flex" 
                  alignItems="center" 
                  justifyContent="center" 
                  height="100%"
                >
                  <Typography color="textSecondary">
                    No monthly donation data available
                  </Typography>
                </Box>
              )}
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Donations by Type
            </Typography>
            <Box height={300}>
              {donationsByTypeData.length > 0 ? (
                <PieChart
                  series={[
                    {
                      data: donationsByTypeData,
                      highlighted: { additionalRadius: 10 }
                    },
                  ]}
                  height={300}
                />
              ) : (
                <Box 
                  display="flex" 
                  alignItems="center" 
                  justifyContent="center" 
                  height="100%"
                >
                  <Typography color="textSecondary">
                    No donation type data available
                  </Typography>
                </Box>
              )}
            </Box>
          </CardContent>
        </Card>
      </Box>
    </Box>
  );
};