import axios, { InternalAxiosRequestConfig } from 'axios';
import { User, Donation, DashboardStats } from '../types';

const API_BASE_URL = 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests if available
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = localStorage.getItem('token');
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Admin Dashboard
export const getDashboardStats = async (): Promise<DashboardStats> => {
  const response = await api.get<DashboardStats>('/admin/stats');
  return response.data;
};

// User Management
export const getUsers = async (): Promise<User[]> => {
  try {
    console.log('Fetching users...');
    const response = await api.get<User[]>('/admin/users');
    console.log('Get users response:', response.data);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error in getUsers:', {
        status: error.response?.status,
        statusText: error.response?.statusText,
        data: error.response?.data
      });
    } else {
      console.error('Non-Axios error in getUsers:', error);
    }
    throw error;
  }
};

export const verifyCharity = async (userId: string): Promise<User> => {
  try {
    console.log('Verifying charity with ID:', userId);
    const response = await api.post<User>(`/admin/users/${userId}/verify`);
    console.log('Verify charity response:', response.data);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error in verifyCharity:', {
        status: error.response?.status,
        statusText: error.response?.statusText,
        data: error.response?.data
      });
    } else {
      console.error('Non-Axios error in verifyCharity:', error);
    }
    throw error;
  }
};

export const updateUserStatus = async (userId: string, status: string): Promise<User> => {
  try {
    console.log('Updating user status:', { userId, status });
    const response = await api.patch<User>(`/admin/users/${userId}/status`, { status });
    console.log('Update user status response:', response.data);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error in updateUserStatus:', {
        status: error.response?.status,
        statusText: error.response?.statusText,
        data: error.response?.data
      });
    } else {
      console.error('Non-Axios error in updateUserStatus:', error);
    }
    throw error;
  }
};

export const deleteUser = async (userId: string): Promise<void> => {
  try {
    console.log('Deleting user with ID:', userId);
    await api.delete(`/admin/users/${userId}`);
    console.log('User deleted successfully');
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error in deleteUser:', {
        status: error.response?.status,
        statusText: error.response?.statusText,
        data: error.response?.data
      });
    } else {
      console.error('Non-Axios error in deleteUser:', error);
    }
    throw error;
  }
};

// Donation Management
export const getDonations = async (status?: Donation['status']): Promise<Donation[]> => {
  try {
    console.log('Making API request to get donations with status:', status);
    const response = await api.get<Donation[]>('/admin/donations', {
      params: { status },
    });
    console.log('API response for donations:', response.data);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error in getDonations:', {
        status: error.response?.status,
        statusText: error.response?.statusText,
        data: error.response?.data,
        config: {
          url: error.config?.url,
          method: error.config?.method,
          params: error.config?.params,
          headers: error.config?.headers
        }
      });
      throw new Error(error.response?.data?.message || 'Failed to fetch donations');
    }
    console.error('Non-Axios error in getDonations:', error);
    throw error;
  }
};

export const updateDonationStatus = async (
  donationId: string, 
  status: Donation['status']
): Promise<Donation> => {
  const response = await api.patch<Donation>(`/admin/donations/${donationId}/status`, { status });
  return response.data;
};

export const deleteDonation = async (donationId: string): Promise<void> => {
  await api.delete(`/admin/donations/${donationId}`);
};

// Authentication
interface LoginResponse {
  token: string;
  user: User;
}

export const login = async (email: string, password: string): Promise<LoginResponse> => {
  const response = await api.post<LoginResponse>('/auth/login', { email, password });
  return response.data;
};

export const logout = (): void => {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
}; 