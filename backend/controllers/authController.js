const User = require('../models/User');
const jwt = require('jsonwebtoken');
const emailService = require('../services/emailService');
const notificationService = require('../services/notificationService');

const generateToken = (user) => {
  return jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
};

exports.register = async (req, res) => {
  try {
    const { email, password, role, name, phone, address, organizationDetails } = req.body;
    
    console.log('Registration attempt:', {
      email,
      role,
      name,
      phone,
      address,
      organizationDetails
    });

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    // Create new user
    const user = new User({
      email,
      password,
      role,
      name,
      phone,
      address,
      organizationDetails,
      status: role === 'charity' ? 'pending' : 'verified' // Automatically verify donors
    });

    console.log('Created user object:', user);

    await user.save();
    console.log('User saved successfully');

    // If charity, send verification email
    if (role === 'charity') {
      await emailService.sendVerificationEmail(email, name);
    }

    // Generate token
    const token = generateToken(user);

    res.status(201).json({
      message: role === 'charity' ? 'Registration pending admin verification' : 'Registration successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Registration failed', error: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check if charity is verified
    if (user.role === 'charity' && !user.isVerified) {
      return res.status(403).json({ message: 'Account pending verification' });
    }

    // Generate token
    const token = generateToken(user);

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
};

exports.verifyCharity = async (req, res) => {
  try {
    const { charityId } = req.params;

    // Only admin can verify charities
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const charity = await User.findById(charityId);
    if (!charity || charity.role !== 'charity') {
      return res.status(404).json({ message: 'Charity not found' });
    }

    charity.isVerified = true;
    await charity.save();

    // Send notification
    await notificationService.notifyCharityVerified(charity);

    res.json({ message: 'Charity verified successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Verification failed', error: error.message });
  }
};

exports.getProfile = async (req, res) => {
  try {
    console.log('Getting profile for user ID:', req.user.id);
    
    const user = await User.findById(req.user.id).select('-password');
    console.log('Found user profile:', user ? 'Profile exists' : 'Profile not found');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Convert Mongoose document to plain object and ensure all fields are included
    const userObject = user.toObject();
    console.log('User profile data:', {
      id: userObject._id,
      name: userObject.name,
      email: userObject.email,
      role: userObject.role,
      status: userObject.status,
      address: userObject.address
    });

    res.json(userObject);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Failed to fetch profile', error: error.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, address, location, profileImage } = req.body;
    console.log('Updating profile for user ID:', req.user.id);
    console.log('Update data:', { name, phone, address, location });
    
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update fields if provided
    if (name) user.name = name;
    if (phone) user.phone = phone;
    if (address) {
      user.address = {
        street: address.street || user.address?.street,
        city: address.city || user.address?.city,
        state: address.state || user.address?.state,
        zipCode: address.zipCode || user.address?.zipCode,
        country: address.country || user.address?.country
      };
    }
    if (location) {
      user.location = {
        type: 'Point',
        coordinates: location.coordinates || [0, 0],
        address: location.address
      };
    }
    if (profileImage) user.profileImage = profileImage;

    await user.save();
    console.log('Profile updated successfully');

    // Convert to object and remove password
    const userObject = user.toObject();
    delete userObject.password;

    res.json({
      message: 'Profile updated successfully',
      user: userObject
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Failed to update profile', error: error.message });
  }
}; 