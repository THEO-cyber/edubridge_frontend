class ApiConstants {
  static const String baseUrl = 'http://192.168.1.152:3000/api/v1';
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // User
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String instructors = '/users/instructors';
  static const String userById = '/users/'; // +:id

  // Courses
  static const String courses = '/courses';
  static const String courseById = '/courses/'; // +:id
  static const String enroll = '/enrollments';
  static const String unenroll = '/enrollments/'; // +:id

  // Lessons
  static const String lessons = '/lessons';

  // Live Sessions
  static const String liveSessions = '/live-sessions';
  static const String liveSessionRequest = '/live-sessions/request';
  static const String joinLiveSession = '/live-sessions/'; // +:id/join

  // Chat
  static const String chatRooms = '/chat/rooms';
  static const String chatRoomMessages = '/chat/rooms/'; // +:roomId/messages
  static const String createChatRoom = '/chat/rooms';

  // Payments
  static const String createPaymentIntent = '/payments/create-intent';
  static const String paymentHistory = '/payments/history';

  // Video
  static const String uploadVideo = '/video/upload';
  static const String getVideo = '/uploads/'; // +filename

  // Reviews, Coupons, Wishlist, Certificates
  static const String reviews = '/reviews';
  static const String coupons = '/coupons';
  static const String wishlist = '/wishlist';
  static const String certificates = '/certificates';

  // Search
  static const String search = '/search';

  // Health
  static const String health = '/health';
  static const String healthReady = '/health/ready';
  static const String healthLive = '/health/live';
}

class AppColors {
  static const blue = 0xFF1A237E;
  static const lightBlue = 0xFF1976D2;
  static const gray = 0xFF90A4AE;
  static const lightGray = 0xFFECEFF1;
}
