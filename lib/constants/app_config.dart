class AppConfig {
  // ─── Stripe ──────────────────────────────────────────────────────────────
  // Replace with your publishable key from dashboard.stripe.com/apikeys
  // Use pk_test_... for testing, pk_live_... for production
  static const String stripePublishableKey =
      'pk_test_REPLACE_WITH_YOUR_STRIPE_PUBLISHABLE_KEY';

  // ─── Jitsi Meet ──────────────────────────────────────────────────────────
  // Public Jitsi server — replace with your own server for production
  static const String jitsiServerUrl = 'https://meet.jit.si';

  // ─── App ─────────────────────────────────────────────────────────────────
  static const String appName = 'EduBridge';
}
