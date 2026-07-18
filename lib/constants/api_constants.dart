class ApiConstants {
  // Build-time configurable so the same binary can target dev/staging/prod
  // without a code change:
  //   flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
  // The default is only a local/dev fallback — set API_BASE_URL for real builds.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://edubridge-proxy.michaelrodri091.workers.dev/api/v1',
  );

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
  static const String googleMobileAuth = '/auth/google/mobile';

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
  static String uploadVideoForLesson(String lessonId) =>
      '/video-processing/upload/$lessonId';
  static const String getVideo = '/uploads/';
  static String videoStatus(String videoId) =>
      '/video-processing/$videoId/status';
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
  static const String instructorApplyPublic = '/applications/instructor/apply';
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
  static String lessonSections(String courseId) =>
      '$lessons/sections/$courseId';
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

  // Admin — users
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminDeactivateUser(String id) => '/admin/users/$id/deactivate';
  static String adminActivateUser(String id) => '/admin/users/$id/activate';
  static String adminChangeRole(String id) => '/admin/users/$id/role';
  // Admin — courses
  static const String adminCourses = '/admin/courses';
  static String adminApproveCourse(String id) => '/admin/courses/$id/approve';
  static String adminRejectCourse(String id) => '/admin/courses/$id/reject';
  static String adminSuspendCourse(String id) => '/admin/courses/$id/suspend';
  // Admin — categories
  static const String adminCategories = '/admin/categories';
  static String adminCategoryById(String id) => '/admin/categories/$id';
  // Admin — stats
  static const String adminStats = '/admin/dashboard/stats';
  static const String adminActivity = '/admin/dashboard/activity';
  // Admin — instructors
  static const String adminInstructors = '/admin/instructors';
  static const String adminReviews = '/admin/reviews';
  static String adminSuspend(String id) => '/admin/instructors/$id/suspend';
  static String adminWarn(String id) => '/admin/instructors/$id/warn';
  static String adminDeleteInstructor(String id) => '/admin/instructors/$id';
  // Admin — notifications
  static const String adminNotifications = '/admin/notifications';
  static const String adminBroadcast = '/admin/notifications/broadcast';
  static String adminNotifyUser(String id) => '/admin/notifications/user/$id';
  // Admin — videos
  static const String adminVideosPending = '/admin/videos/pending';
  static String adminApproveVideo(String id) => '/admin/videos/$id/approve';
  static String adminRejectVideo(String id) => '/admin/videos/$id/reject';
  // Admin — applications
  static const String adminApplications = '/applications/instructor';
  static const String adminApplicationStats = '/applications/instructor/stats';
  static String adminReviewApplication(String id) => '/applications/instructor/$id/review';
  // Admin — payouts
  static const String adminPayouts = '/payouts/admin/all';

  // Session reviews (instructor)
  static String sessionReviews(String sessionId) => '/live-sessions/$sessionId/reviews';

  // Reports (additional)
  static const String reportStats = '/reports/stats';
  static String reviewReport(String id) => '/reports/$id/review';

  // Applications (instructor)
  static const String instructorApplicationSubmit = '/applications/instructor';
  static const String myInstructorApplicationStatus = '/applications/instructor/mine';

  // Coupons (admin)
  static const String adminCoupons = '/coupons';
  static String adminCouponById(String id) => '/coupons/$id';

  // Payouts
  static const String payoutsDashboardUrl = '/payouts/dashboard';
  static const String payoutsConnectUrl = '/payouts/connect';
  static const String payoutsRequestUrl = '/payouts/request';
  static const String payoutsHistoryUrl = '/payouts/history';

  // Quiz (instructor)
  static String createQuizForLesson(String lessonId) => '/quizzes/lessons/$lessonId';
  static String quizQuestions(String quizId) => '/quizzes/$quizId/questions';
  static String updateQuestion(String questionId) => '/quizzes/questions/$questionId';
  static String deleteQuestion(String questionId) => '/quizzes/questions/$questionId';
  static String quizResultsAdmin(String quizId) => '/quizzes/$quizId/results';
  static String publishQuiz(String quizId) => '/quizzes/$quizId/publish';
  static String updateQuiz(String quizId) => '/quizzes/$quizId';

  // Video — presigned 3-step upload flow
  static String initiateUpload(String lessonId) =>
      '/video-processing/initiate-upload/$lessonId';
  static String completeUpload(String videoId) =>
      '/video-processing/complete-upload/$videoId';
  static String streamUrlForVideo(String videoId) =>
      '/video-processing/stream-url/$videoId';

  // Payouts — instructor earnings
  static const String payoutsEarnings = '/payouts/earnings';
}

class AppColors {
  static const blue = 0xFF1A237E;
  static const lightBlue = 0xFF1976D2;
  static const gray = 0xFF90A4AE;
  static const lightGray = 0xFFECEFF1;
}
