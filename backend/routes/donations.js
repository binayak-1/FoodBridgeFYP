const express = require('express');
const router = express.Router();
const donationController = require('../controllers/donationController');
const auth = require('../middleware/auth');

// Protected routes - all require authentication
router.use(auth);

// Donation routes
router.post('/', donationController.createDonation);
router.get('/', donationController.getDonations);
router.get('/donor', donationController.getDonorDonations);
router.get('/charity', donationController.getCharityDonations);
router.get('/:id', donationController.getDonationById);
router.post('/:id/accept', donationController.acceptDonation);
router.put('/:id/status', donationController.updateDonationStatus);

module.exports = router; 