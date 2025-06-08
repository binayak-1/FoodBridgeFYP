const DONATION_STATUS = {
  PENDING: 'pending',
  AVAILABLE: 'available',
  ACCEPTED: 'accepted',
  COMPLETED: 'completed',
  EXPIRED: 'expired'
};

const FOOD_TYPES = {
  COOKED: 'Cooked',
  RAW: 'Raw',
  PACKAGED: 'Packaged',
  BEVERAGES: 'Beverages',
  OTHER: 'Other'
};

const QUANTITY_UNITS = {
  KG: 'kg',
  ITEMS: 'items',
  PACKAGES: 'packages',
  LITERS: 'liters'
};

// Explicit enum arrays for Mongoose
const DONATION_STATUS_ENUM = ['pending', 'available', 'accepted', 'completed', 'expired'];
const FOOD_TYPES_ENUM = ['Cooked', 'Raw', 'Packaged', 'Beverages', 'Other'];
const QUANTITY_UNITS_ENUM = ['kg', 'items', 'packages', 'liters'];

module.exports = {
  DONATION_STATUS,
  FOOD_TYPES,
  QUANTITY_UNITS,
  DONATION_STATUS_ENUM,
  FOOD_TYPES_ENUM,
  QUANTITY_UNITS_ENUM
}; 