const jwt = require('jsonwebtoken');
const User = require('../models/User');

module.exports = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '');
    console.log('Received token:', token ? 'Token exists' : 'No token');

    if (!token) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('Decoded token payload:', decoded);

    // Find user
    const user = await User.findOne({ _id: decoded.id });
    console.log('Found user:', user ? 'User exists' : 'User not found', 'ID:', decoded.id);
    
    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    // Add user to request
    req.user = user;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(401).json({ message: 'Invalid token', error: error.message });
  }
}; 