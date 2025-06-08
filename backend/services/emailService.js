const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      }
    });
  }

  async sendVerificationEmail(email, name, verificationLink) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: email,
      subject: 'Verify Your Food Bridge Charity Account',
      html: `
        <h1>Welcome to Food Bridge!</h1>
        <p>Dear ${name},</p>
        <p>Thank you for registering as a charity organization with Food Bridge. Your account is currently under review.</p>
        <p>We will notify you once your account has been verified by our admin team.</p>
        <p>Best regards,<br>The Food Bridge Team</p>
      `
    };

    return this.transporter.sendMail(mailOptions);
  }

  async sendDonationAcceptedEmail(donorEmail, donorName, charityName, donationTitle) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: donorEmail,
      subject: 'Your Donation Has Been Accepted!',
      html: `
        <h1>Donation Accepted</h1>
        <p>Dear ${donorName},</p>
        <p>Your donation "${donationTitle}" has been accepted by ${charityName}.</p>
        <p>They will contact you shortly to arrange the pickup.</p>
        <p>Thank you for making a difference!</p>
        <p>Best regards,<br>The Food Bridge Team</p>
      `
    };

    return this.transporter.sendMail(mailOptions);
  }

  async sendCharityVerificationEmail(charityEmail, charityName) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: charityEmail,
      subject: 'Your Food Bridge Account Has Been Verified!',
      html: `
        <h1>Account Verified</h1>
        <p>Dear ${charityName},</p>
        <p>Congratulations! Your Food Bridge charity account has been verified by our admin team.</p>
        <p>You can now start accepting donations through our platform.</p>
        <p>Thank you for joining our mission to reduce food waste and help those in need.</p>
        <p>Best regards,<br>The Food Bridge Team</p>
      `
    };

    return this.transporter.sendMail(mailOptions);
  }
}

module.exports = new EmailService(); 