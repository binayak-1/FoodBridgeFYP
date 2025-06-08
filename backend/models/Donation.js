const mongoose = require('mongoose');
const { 
  DONATION_STATUS,
  DONATION_STATUS_ENUM,
  FOOD_TYPES_ENUM,
  QUANTITY_UNITS_ENUM
} = require('../constants/donationConstants');

// Export the constants first
exports.DONATION_STATUS = DONATION_STATUS;
exports.DONATION_STATUS_ENUM = DONATION_STATUS_ENUM;
exports.FOOD_TYPES_ENUM = FOOD_TYPES_ENUM;
exports.QUANTITY_UNITS_ENUM = QUANTITY_UNITS_ENUM;

const donationSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true,
    trim: true
  },
  donor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  acceptedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  status: {
    type: String,
    required: true,
    enum: DONATION_STATUS_ENUM,
    default: DONATION_STATUS.AVAILABLE
  },
  foodType: {
    type: String,
    required: true,
    enum: FOOD_TYPES_ENUM
  },
  quantity: {
    type: Number,
    required: true,
    min: 0
  },
  quantityUnit: {
    type: String,
    required: true,
    enum: QUANTITY_UNITS_ENUM
  },
  expiryDate: {
    type: Date,
    required: true
  },
  pickupAddress: {
    street: {
      type: String,
      required: true
    },
    city: {
      type: String,
      required: true
    },
    state: {
      type: String,
      required: true
    },
    zipCode: {
      type: String,
      required: true
    }
  },
  pickupTimeSlot: {
    from: {
      type: Date,
      required: true
    },
    to: {
      type: Date,
      required: true
    }
  },
  specialInstructions: {
    type: String,
    trim: true
  },
  images: [{
    type: String,
    trim: true
  }]
}, {
  timestamps: true
});

// Create geospatial index for pickup location
donationSchema.index({ 'pickupAddress.location': '2dsphere' });

// Auto-update status to expired when expiryDate is reached
donationSchema.pre('save', function(next) {
  if (this.expiryDate < new Date()) {
    this.status = DONATION_STATUS.EXPIRED;
  }
  next();
});

// Create the model
const Donation = mongoose.models.Donation || mongoose.model('Donation', donationSchema);

// Export the model last
module.exports = Donation; 