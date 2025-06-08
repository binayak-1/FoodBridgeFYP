export interface User {
  _id: string;
  name: string;
  email: string;
  phone?: string;
  address?: string | {
    street: string;
    city: string;
    state: string;
    zipCode: string;
  };
  role: 'admin' | 'donor' | 'charity';
  status: 'pending' | 'verified' | 'rejected';
  isVerified: boolean;
  registrationNumber?: string;
  description?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface Donation {
  _id: string;
  title: string;
  description: string;
  donor: {
    _id: string;
    name: string;
    email: string;
  } | null;
  charity: {
    _id: string;
    name: string;
    email: string;
  } | null;
  status: 'pending' | 'available' | 'accepted' | 'completed' | 'expired';
  foodType: string;
  quantity: number;
  quantityUnit: string;
  expiryDate: string;
  pickupAddress: {
    street: string;
    city: string;
    state: string;
    zipCode: string;
  };
  pickupTimeSlot: {
    from: string;
    to: string;
  };
  createdAt: string;
  updatedAt: string;
}

export interface DashboardStats {
  totalUsers: number;
  totalDonors: number;
  totalCharities: number;
  pendingVerifications: number;
  totalDonations: number;
  activeDonations: number;
  completedDonations: number;
  expiredDonations: number;
  monthlyDonations: Array<{
    month: string;
    count: number;
  }>;
  donationsByType: Array<{
    type: string;
    count: number;
  }>;
} 