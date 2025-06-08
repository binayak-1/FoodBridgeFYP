const Notification = require('../models/Notification');
const emailService = require('./emailService');

class NotificationService {
  async createNotification(data) {
    try {
      const notification = new Notification(data);
      await notification.save();
      return notification;
    } catch (error) {
      throw new Error('Failed to create notification: ' + error.message);
    }
  }

  async getUnreadNotifications(userId) {
    try {
      return await Notification.find({
        recipient: userId,
        isRead: false
      }).sort({ createdAt: -1 });
    } catch (error) {
      throw new Error('Failed to fetch notifications: ' + error.message);
    }
  }

  async markAsRead(notificationId) {
    try {
      return await Notification.findByIdAndUpdate(
        notificationId,
        { isRead: true },
        { new: true }
      );
    } catch (error) {
      throw new Error('Failed to mark notification as read: ' + error.message);
    }
  }

  async notifyDonationAccepted(donation, charity) {
    try {
      // Create in-app notification
      await this.createNotification({
        recipient: donation.donor,
        type: 'donation_accepted',
        title: 'Donation Accepted',
        message: `Your donation "${donation.title}" has been accepted by ${charity.name}`,
        relatedDonation: donation._id
      });

      // Send email notification
      await emailService.sendDonationAcceptedEmail(
        donation.donor.email,
        donation.donor.name,
        charity.name,
        donation.title
      );
    } catch (error) {
      throw new Error('Failed to send donation accepted notification: ' + error.message);
    }
  }

  async notifyCharityVerified(charity) {
    try {
      // Create in-app notification
      await this.createNotification({
        recipient: charity._id,
        type: 'charity_verified',
        title: 'Account Verified',
        message: 'Your charity account has been verified by the admin. You can now start accepting donations.'
      });

      // Send email notification
      await emailService.sendCharityVerificationEmail(
        charity.email,
        charity.name
      );
    } catch (error) {
      throw new Error('Failed to send charity verification notification: ' + error.message);
    }
  }
}

module.exports = new NotificationService(); 