const DonationModel = require('../models/Donation');
const { 
  DONATION_STATUS, 
  DONATION_STATUS_ENUM,
  FOOD_TYPES_ENUM,
  QUANTITY_UNITS_ENUM 
} = require('../constants/donationConstants');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

exports.createDonation = async (req, res) => {
  try {
    console.log('Creating donation with data:', JSON.stringify(req.body, null, 2));
    console.log('User:', JSON.stringify(req.user, null, 2));
    console.log('Valid status values:', DONATION_STATUS_ENUM);
    console.log('Valid food types:', FOOD_TYPES_ENUM);
    console.log('Valid units:', QUANTITY_UNITS_ENUM);

    // Validate required fields
    const requiredFields = ['title', 'description', 'foodType', 'quantity', 'quantityUnit', 'expiryDate', 'pickupAddress', 'pickupTimeSlot'];
    for (const field of requiredFields) {
      if (!req.body[field]) {
        console.log(`Missing required field: ${field}`);
        throw new Error(`Missing required field: ${field}`);
      }
    }

    // Additional validation for nested objects
    if (!req.body.pickupAddress?.street || 
        !req.body.pickupAddress?.city || 
        !req.body.pickupAddress?.state || 
        !req.body.pickupAddress?.zipCode) {
      throw new Error('Missing required address fields');
    }

    if (!req.body.pickupTimeSlot?.from || !req.body.pickupTimeSlot?.to) {
      throw new Error('Missing required pickup time fields');
    }

    // Validate enum values before creating the document
    if (!FOOD_TYPES_ENUM.includes(req.body.foodType)) {
      throw new Error(`Invalid food type: ${req.body.foodType}. Must be one of: ${FOOD_TYPES_ENUM.join(', ')}`);
    }

    if (!QUANTITY_UNITS_ENUM.includes(req.body.quantityUnit)) {
      throw new Error(`Invalid unit: ${req.body.quantityUnit}. Must be one of: ${QUANTITY_UNITS_ENUM.join(', ')}`);
    }

    const donationData = {
      ...req.body,
      donor: req.user.id,
      status: DONATION_STATUS.AVAILABLE
    };

    console.log('Creating donation with processed data:', JSON.stringify(donationData, null, 2));
    console.log('Status being set to:', donationData.status);
    console.log('Food type being set to:', donationData.foodType);
    console.log('Unit being set to:', donationData.quantityUnit);

    const donation = new DonationModel(donationData);
    console.log('Created donation object:', JSON.stringify(donation.toObject(), null, 2));
    
    await donation.save();
    console.log('Donation saved successfully');

    // Create notification for the donor
    await notificationService.createNotification({
      recipient: req.user.id,
      type: 'donation_created',
      title: 'Donation Created',
      message: `Your donation "${donation.title}" has been created successfully`,
      relatedDonation: donation._id
    });

    // Notify nearby charities about new donation
    const nearbyCharities = await User.find({
      role: 'charity',
      isVerified: true,
      'address.city': req.body.pickupAddress.city
    });

    console.log(`Found ${nearbyCharities.length} nearby charities`);

    for (const charity of nearbyCharities) {
      await notificationService.createNotification({
        recipient: charity._id,
        type: 'new_donation',
        title: 'New Donation Available',
        message: `New donation "${donation.title}" is available in your area`,
        relatedDonation: donation._id
      });
    }

    res.status(201).json(donation);
  } catch (error) {
    console.error('Error creating donation:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      message: 'Failed to create donation', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

exports.getDonations = async (req, res) => {
  try {
    const { status, city } = req.query;
    const query = {};

    if (status) query.status = status;
    if (city) query['pickupAddress.city'] = city;

    const donations = await DonationModel.find(query)
      .populate('donor', 'name email phone')
      .populate('acceptedBy', 'name email phone')
      .sort({ createdAt: -1 });

    res.json(donations);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch donations', error: error.message });
  }
};

exports.getDonationById = async (req, res) => {
  try {
    const donation = await DonationModel.findById(req.params.id)
      .populate('donor', 'name email phone')
      .populate('acceptedBy', 'name email phone');

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    res.json(donation);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch donation', error: error.message });
  }
};

exports.acceptDonation = async (req, res) => {
  try {
    const donation = await DonationModel.findById(req.params.id);
    
    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (donation.status !== 'available') {
      return res.status(400).json({ message: 'Donation is not available' });
    }

    if (req.user.role !== 'charity') {
      return res.status(403).json({ message: 'Only charities can accept donations' });
    }

    if (!req.user.isVerified) {
      return res.status(403).json({ message: 'Your account needs to be verified to accept donations' });
    }

    donation.status = 'accepted';
    donation.acceptedBy = req.user.id;
    donation.acceptedAt = new Date();
    await donation.save();

    // Get donor and charity details for notification
    const donor = await User.findById(donation.donor);
    const charity = await User.findById(req.user.id);

    // Send notifications
    await notificationService.notifyDonationAccepted(donation, charity);

    res.json(donation);
  } catch (error) {
    res.status(500).json({ message: 'Failed to accept donation', error: error.message });
  }
};

exports.updateDonationStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const donation = await DonationModel.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    // Only donor or accepted charity can update status
    if (donation.donor.toString() !== req.user.id && 
        donation.acceptedBy?.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    donation.status = status;
    await donation.save();

    res.json(donation);
  } catch (error) {
    res.status(500).json({ message: 'Failed to update donation status', error: error.message });
  }
};

exports.getDonorDonations = async (req, res) => {
  try {
    const donations = await DonationModel.find({ donor: req.user.id })
      .populate('acceptedBy', 'name email phone')
      .sort({ createdAt: -1 });

    res.json(donations);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch donations', error: error.message });
  }
};

exports.getCharityDonations = async (req, res) => {
  try {
    const donations = await DonationModel.find({ acceptedBy: req.user.id })
      .populate('donor', 'name email phone')
      .sort({ createdAt: -1 });

    res.json(donations);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch donations', error: error.message });
  }
}; 