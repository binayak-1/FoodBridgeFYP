require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('MONGODB_URI environment variable is not set');
  process.exit(1);
}

mongoose.connect(MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB Atlas');
    
    try {
      const existingAdmin = await User.findOne({ email: 'binayak@admin.com' });
      if (existingAdmin) {
        console.log('Admin user already exists');
        process.exit(0);
      }

      const adminUser = new User({
        name: 'Binayak',
        email: 'binayak@admin.com',
        password: 'Binayak123',
        role: 'admin',
        status: 'verified',
        phone: '1234567890',
        address: {
          street: 'Admin Street',
          city: 'Admin City',
          state: 'Admin State',
          zipCode: '12345'
        }
      });

      await adminUser.save();
      console.log('Admin user created successfully');
    } catch (error) {
      console.error('Error creating admin user:', error);
    } finally {
      await mongoose.disconnect();
      console.log('Disconnected from MongoDB');
      process.exit(0);
    }
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  }); 