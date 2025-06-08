const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Donation = require('../models/Donation');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');

// Apply auth and admin middleware to all routes
router.use(auth, admin);

// Get dashboard statistics
router.get('/stats', async (req, res) => {
  try {
    const [
      totalUsers,
      totalDonors,
      totalCharities,
      pendingVerifications,
      totalDonations,
      activeDonations,
      completedDonations,
      expiredDonations,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ role: 'donor' }),
      User.countDocuments({ role: 'charity' }),
      User.countDocuments({ role: 'charity', status: 'pending' }),
      Donation.countDocuments(),
      Donation.countDocuments({ status: 'active' }),
      Donation.countDocuments({ status: 'completed' }),
      Donation.countDocuments({ status: 'expired' }),
    ]);

    // Get monthly donations for the last 6 months
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    
    const monthlyDonations = await Donation.aggregate([
      {
        $match: {
          createdAt: { $gte: sixMonthsAgo }
        }
      },
      {
        $group: {
          _id: {
            month: { $month: '$createdAt' },
            year: { $year: '$createdAt' }
          },
          count: { $sum: 1 }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 }
      }
    ]);

    // Get donations by type
    const donationsByType = await Donation.aggregate([
      {
        $group: {
          _id: '$foodType',
          count: { $sum: 1 }
        }
      }
    ]);

    res.json({
      totalUsers,
      totalDonors,
      totalCharities,
      pendingVerifications,
      totalDonations,
      activeDonations,
      completedDonations,
      expiredDonations,
      monthlyDonations: monthlyDonations.map(item => ({
        month: new Date(0, item._id.month - 1).toLocaleString('default', { month: 'short' }),
        count: item.count
      })),
      donationsByType: donationsByType.map(item => ({
        type: item._id,
        count: item.count
      }))
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching statistics', error: error.message });
  }
});

// Get all users
router.get('/users', async (req, res) => {
  try {
    console.log('Fetching all users...');
    
    // First, ensure all users have correct isVerified value
    await User.updateMany(
      { status: 'verified' },
      { isVerified: true }
    );
    await User.updateMany(
      { status: { $ne: 'verified' } },
      { isVerified: false }
    );
    
    const users = await User.find()
      .select('-password')
      .sort({ createdAt: -1 });
    
    console.log('Users before sending:', users.map(user => ({
      id: user._id,
      name: user.name,
      role: user.role,
      status: user.status,
      isVerified: user.isVerified
    })));
    
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Error fetching users', error: error.message });
  }
});

// Verify a charity
router.post('/users/:id/verify', async (req, res) => {
  try {
    console.log('Verifying charity with ID:', req.params.id);
    const user = await User.findById(req.params.id);
    
    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.role !== 'charity') {
      console.log('User is not a charity:', user.role);
      return res.status(400).json({ message: 'Only charity accounts can be verified' });
    }

    console.log('Before update:', { status: user.status, isVerified: user.isVerified });
    
    // Update both fields
    await User.findByIdAndUpdate(
      req.params.id,
      { 
        $set: { 
          status: 'verified',
          isVerified: true
        }
      },
      { new: true }
    );

    // Fetch the updated user
    const updatedUser = await User.findById(req.params.id);
    console.log('After update:', { 
      status: updatedUser.status, 
      isVerified: updatedUser.isVerified 
    });

    // Return the updated user object
    res.json(updatedUser);
  } catch (error) {
    console.error('Error verifying charity:', error);
    res.status(500).json({ message: 'Error verifying charity', error: error.message });
  }
});

// Delete a user
router.delete('/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Delete all donations associated with this user
    if (user.role === 'donor') {
      await Donation.deleteMany({ donor: user._id });
    }

    await user.deleteOne();
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting user', error: error.message });
  }
});

// Get all donations
router.get('/donations', async (req, res) => {
  try {
    console.log('Admin - Fetching donations with query:', req.query);
    const { status } = req.query;
    const query = status && status !== 'all' ? { status } : {};

    console.log('Executing donation query:', query);
    const donations = await Donation.find(query)
      .populate('donor', 'name email')
      .populate('acceptedBy', 'name email')
      .sort({ createdAt: -1 })
      .lean();

    console.log(`Found ${donations.length} donations`);

    // Transform the data to match frontend expectations
    const transformedDonations = donations.map(donation => {
      console.log('Processing donation:', donation._id);
      return {
        _id: donation._id,
        title: donation.title,
        description: donation.description,
        donor: donation.donor || { name: 'Unknown Donor', email: 'unknown' },
        charity: donation.acceptedBy || null,
        status: donation.status,
        foodType: donation.foodType,
        quantity: donation.quantity,
        quantityUnit: donation.quantityUnit,
        expiryDate: donation.expiryDate,
        pickupAddress: donation.pickupAddress,
        pickupTimeSlot: donation.pickupTimeSlot,
        createdAt: donation.createdAt,
        updatedAt: donation.updatedAt
      };
    });

    console.log('Sending transformed donations to client');
    res.json(transformedDonations);
  } catch (error) {
    console.error('Error in /admin/donations:', error);
    res.status(500).json({ 
      message: 'Error fetching donations', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Update user status
router.patch('/users/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Validate status
    if (!['pending', 'verified', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status value' });
    }

    user.status = status;
    // Update isVerified based on status
    user.isVerified = status === 'verified';
    await user.save();

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Error updating user status', error: error.message });
  }
});

module.exports = router;