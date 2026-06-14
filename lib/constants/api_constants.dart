class ApiConstants {
  static const String baseUrl = 'http://10.167.251.55:3000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String googleAuth = '/auth/google';

  // 2FA
  static const String twoFaEnable = '/auth/2fa/enable';
  static const String twoFaConfirm = '/auth/2fa/confirm';
  static const String twoFaDisable = '/auth/2fa/disable';
  static const String twoFaVerify = '/auth/2fa/verify';

  // User
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String updateStudentProfile = '/users/profile/student';
  static const String updateInstructorProfile = '/users/profile/instructor';
  static const String instructors = '/users/instructors';
  static const String userById = '/users/';
  static const String deleteAccount = '/users/account';

  // Courses
  static const String courses = '/courses';
  static const String courseById = '/courses/';
  static const String instructorMyCourses = '/courses/instructor/my-courses';
  static const String courseSlugPrefix = '/courses/slug';
  static const String enroll = '/enrollments';
  static const String unenroll = '/enrollments/';

  // Lessons
  static const String lessons = '/lessons';
  static const String sections = '/sections';

  // Live Sessions
  static const String liveSessions = '/live-sessions';
  static const String liveSessionRequest = '/live-sessions/request';
  static const String liveSessionRequests = '/live-sessions/requests';
  static const String joinLiveSession = '/live-sessions/';
  static const String liveSessionMySessions = '/live-sessions/my-sessions';
  static String liveSessionAvailability(String instructorId) =>
      '/live-sessions/availability/$instructorId';
  static const String liveSessionMyAvailability =
      '/live-sessions/availability/my-slots';

  // Chat
  static const String chatRooms = '/chat/rooms';
  static const String chatRoomMessages = '/chat/rooms/';
  static const String createChatRoom = '/chat/rooms';

  // Payments
  static const String createPaymentIntent = '/payments/create-intent';
  static const String paymentHistory = '/payments/history';
  static String enrollFree(String courseId) =>
      '/payments/enroll-free/$courseId';
  static String paymentInvoice(String paymentId) =>
      '/payments/$paymentId/invoice';
  static String paymentRefund(String paymentId) =>
      '/payments/$paymentId/refund';

  // Video
  static const String uploadVideo = '/video-processing/upload';
  static const String getVideo = '/uploads/';
  static String videoStatus(String videoId) =>
      '/video-processing/status/$videoId';
  static String videoStream(String videoId) =>
      '/video-processing/stream/$videoId';
  static String videoHls(String videoId) =>
      '/video-processing/hls/$videoId/manifest';

  // Quizzes
  static const String quizzes = '/quizzes';
  static String quizForLesson(String lessonId) => '/quizzes/lesson/$lessonId';
  static String quizById(String quizId) => '/quizzes/$quizId';
  static String createQuiz(String lessonId) => '/quizzes/lessons/$lessonId';
  static String startQuiz(String quizId) => '/quizzes/$quizId/start';
  static String submitQuizAttempt(String attemptId) =>
      '/quizzes/attempts/$attemptId/submit';
  static String myQuizAttempts(String quizId) => '/quizzes/$quizId/my-attempts';
  static String quizResults(String quizId) => '/quizzes/$quizId/results';

  // Notes
  static const String notes = '/notes';
  static String notesForLesson(String lessonId) => '/notes/lessons/$lessonId';
  static String noteById(String noteId) => '/notes/$noteId';

  // Discussions
  static const String discussionThreads = '/discussions/threads';
  static String courseDiscussions(String courseId) =>
      '/discussions/threads/$courseId';
  static String discussionThread(String threadId) =>
      '/discussions/thread/$threadId';
  static String replyToThread(String threadId) =>
      '/discussions/thread/$threadId/reply';
  static String markAnswered(String threadId, String replyId) =>
      '/discussions/thread/$threadId/answer/$replyId';

  // Announcements
  static String courseAnnouncements(String courseId) =>
      '/announcements/courses/$courseId';
  static String announcementById(String id) => '/announcements/$id';

  // Reviews
  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my';

  // Coupons
  static const String coupons = '/coupons';
  static const String couponsActive = '/coupons/active';
  static const String couponsApply = '/coupons/apply';
  static const String couponsValidate = '/coupons/validate';

  // Wishlist
  static const String wishlist = '/wishlist';

  // Certificates
  static const String certificates = '/certificates';

  // Notifications
  static const String notifications = '/notifications';
  static const String registerFcmToken = '/notifications/device-token';
  static const String markAllNotificationsRead =
      '/notifications/mark-all-read';

  // Analytics
  static const String studentAnalytics = '/analytics/student/progress';
  static const String instructorAnalytics = '/analytics/instructor/dashboard';
  static const String courseAnalyticsPrefix = '/analytics/course/';
  static String instructorAnalyticsById(String id) =>
      '/analytics/instructor/$id/dashboard';
  static String courseAnalytics(String courseId) =>
      '$courseAnalyticsPrefix$courseId';

  // Search
  static const String search = '/search';
  static const String searchSuggestions = '/search/suggestions';
  static const String searchCategories = '/search/categories';
  static const String searchFeatured = '/search/featured';

  // Reports
  static const String reports = '/reports';
  static const String myReports = '/reports/my';

  // Email Preferences
  static const String emailPreferences = '/email-preferences';

  // Instructor Applications
  static const String instructorApplication = '/applications/instructor';
  static const String myInstructorApplication = '/applications/instructor/mine';

  // Payouts
  static const String payoutsDashboard = '/payouts/dashboard';
  static const String payoutsConnect = '/payouts/connect';
  static const String payoutsHistory = '/payouts/history';
  static const String payoutsRequest = '/payouts/request';

  // Platform Settings
  static const String publicSettings = '/settings/public';

  // Health
  static const String health = '/health';
  static const String healthReady = '/health/ready';
  static const String healthLive = '/health/live';

  // --- Helper methods ---

  static String courseDetails(String id) => '$courses/$id';
  static String courseBySlug(String slug) => '$courseSlugPrefix/$slug';
  static String publishCourse(String id) => '${courseDetails(id)}/publish';
  static String courseSections(String courseId) =>
      '${courseDetails(courseId)}/sections';
  static String courseSection(String courseId, String sectionId) =>
      '${courseSections(courseId)}/$sectionId';
  static String sectionLessons(String sectionId) =>
      '$sections/$sectionId/lessons';
  static String lessonDetails(String lessonId) => '$lessons/$lessonId';
  static String enrollmentDetails(String enrollmentId) =>
      '$enroll/$enrollmentId';
  static String enrollmentProgress(String courseId) =>
      '$enroll/courses/$courseId/progress';
  static String lessonProgress(String lessonId) =>
      '$enroll/lessons/$lessonId/progress';
  static String wishlistCourse(String courseId) => '$wishlist/$courseId';
  static String wishlistCheck(String courseId) =>
      '$wishlist/$courseId/check';
  static String courseReviews(String courseId) => '$reviews/course/$courseId';
  static String myReviewForCourse(String courseId) => '$myReviews/$courseId';
  static String liveSessionConfirm(String requestId) =>
      '$liveSessionRequests/$requestId/confirm';
  static String liveSessionCancel(String requestId) =>
      '$liveSessionRequests/$requestId/cancel';

  // Group live-session flow (v2)
  static const String liveSessionUpcoming = '/live-sessions/upcoming';
  static String liveSessionByInstructor(String id) =>
      '/live-sessions/instructor/$id';
  static String liveSessionByCourse(String id) => '/live-sessions/course/$id';
  static String liveSessionApply(String id) => '/live-sessions/$id/apply';
  static String liveSessionApplications(String id) =>
      '/live-sessions/$id/applications';
  static String liveSessionApplicationAccept(String id) =>
      '/live-sessions/applications/$id/accept';
  static String liveSessionApplicationReject(String id) =>
      '/live-sessions/applications/$id/reject';
  static String liveSessionNotifyAccepted(String id) =>
      '/live-sessions/$id/notify-accepted';
  static String chatMessages(String roomId) => '$chatRooms/$roomId/messages';
  static String chatRead(String roomId) => '$chatRooms/$roomId/read';
  static String courseChatRoom(String courseId) =>
      '$chatRooms/course/$courseId';
  static String certificateForCourse(String courseId) =>
      '$certificates/$courseId';
  static String certificateDownload(String id) => '$certificates/$id/download';
  static String verifyCertificate(String number) =>
      '$certificates/verify/$number';
  static String notificationRead(String id) => '$notifications/$id/read';
  static String deleteNotification(String id) => '$notifications/$id';

  // Admin
  static const String adminInstructors = '/admin/instructors';
  static const String adminReviews = '/admin/reviews';
  static String adminSuspend(String id) => '/admin/instructors/$id/suspend';
  static String adminWarn(String id) => '/admin/instructors/$id/warn';
  static String adminDeleteInstructor(String id) => '/admin/instructors/$id';

  // Session reviews (instructor)
  static String sessionReviews(String sessionId) => '/live-sessions/$sessionId/reviews';
}

class AppColors {
  static const blue = 0xFF1A237E;
  static const lightBlue = 0xFF1976D2;
  static const gray = 0xFF90A4AE;
  static const lightGray = 0xFFECEFF1;
}
