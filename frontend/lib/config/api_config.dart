class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Email configuration for admin notifications
  static const String adminEmail = 'admin@foodbridge.com';
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  
  // API endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String donationsEndpoint = '/donations';
  static const String adminEndpoint = '/admin';
  
  // Timeout durations
  static const int connectionTimeout = 10000; // 10 seconds
  static const int receiveTimeout = 5000; // 5 seconds
} 