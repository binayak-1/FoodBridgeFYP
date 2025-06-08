const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');

// Get user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching profile', error: error.message });
  }
});

// Update user profile
router.patch('/profile', auth, async (req, res) => {
  const updates = Object.keys(req.body);
  const allowedUpdates = ['name', 'phone', 'address', 'organizationDetails'];
  const isValidOperation = updates.every(update => allowedUpdates.includes(update));

  if (!isValidOperation) {
    return res.status(400).json({ message: 'Invalid updates!' });
  }

  try {
    const user = await User.findById(req.user.id);
    updates.forEach(update => user[update] = req.body[update]);
    await user.save();
    res.json(user);
  } catch (error) {
    res.status(400).json({ message: 'Error updating profile', error: error.message });
  }
});

module.exports = router; 