import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:food_bridge/config/api_config.dart';

class EmailService {
  static final smtpServer = SmtpServer(
    ApiConfig.smtpHost,
    port: ApiConfig.smtpPort,
    username: ApiConfig.adminEmail,
    // Note: Password should be stored securely, preferably in environment variables
    password: const String.fromEnvironment('SMTP_PASSWORD'),
    ssl: false,
    allowInsecure: true,
  );

  static Future<void> sendVerificationEmail(String email, String name) async {
    final message = Message()
      ..from = Address(ApiConfig.adminEmail, 'Food Bridge Admin')
      ..recipients.add(email)
      ..subject = 'Your Charity Account has been Verified'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2196F3;">Congratulations!</h1>
          <p>Dear $name,</p>
          <p>Your charity account on Food Bridge has been verified. You can now start accepting donations and helping those in need.</p>
          <p>Here's what you can do now:</p>
          <ul>
            <li>Browse available donations in your area</li>
            <li>Accept donations that match your needs</li>
            <li>Coordinate pickup with donors</li>
            <li>Track your donation history</li>
          </ul>
          <p>If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
          <p>Best regards,<br>Food Bridge Team</p>
          <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666;">
            <p>This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  static Future<void> sendDonationNotification({
    required String recipientEmail,
    required String recipientName,
    required String donationTitle,
    required String donorName,
    required String status,
  }) async {
    final message = Message()
      ..from = Address(ApiConfig.adminEmail, 'Food Bridge Admin')
      ..recipients.add(recipientEmail)
      ..subject = 'Donation $status: $donationTitle'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2196F3;">Donation Update</h1>
          <p>Dear $recipientName,</p>
          <p>The donation "$donationTitle" by $donorName has been $status.</p>
          <p>Please log in to your Food Bridge account to view more details and take necessary actions.</p>
          <p>Best regards,<br>Food Bridge Team</p>
          <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666;">
            <p>This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send donation notification: $e');
    }
  }
} 