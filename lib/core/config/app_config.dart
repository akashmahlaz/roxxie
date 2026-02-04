/// 🔐 App Configuration
///
/// Environment-specific configuration values
/// For production, these should be loaded from secure sources
library;

/// Application configuration
class AppConfig {
  // Stripe Configuration
  // In production, load from secure storage or remote config
  static const String stripePublishableKeyTest =
      'pk_test_51SmC3CFPTeSKTr2qb1nt2PAyUvI85xpBGjuEXnjD8s91QDROaCMaPNDmmUKTZ3KvXMPMDR0V13PzHZA8C2PqZcOO00SFROGUN9';
  
  // TODO: Replace with production key before release
  static const String stripePublishableKeyProd =
      'pk_live_YOUR_PRODUCTION_KEY_HERE';
  
  /// Get the appropriate Stripe key based on environment
  static String get stripePublishableKey {
    // Check if running in release mode
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? stripePublishableKeyProd : stripePublishableKeyTest;
  }

  // API Configuration
  static const String apiBaseUrlDev = 'https://api.gigmatch.com';
  static const String apiBaseUrlProd = 'https://api.gigmatch.com';
  
  static String get apiBaseUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? apiBaseUrlProd : apiBaseUrlDev;
  }

  // App URLs
  static const String privacyPolicyUrl = 'https://gigmatch.com/privacy-policy';
  static const String termsOfServiceUrl = 'https://gigmatch.com/terms';
  static const String supportEmail = 'support@gigmatch.com';
  static const String websiteUrl = 'https://gigmatch.com';
  
  // App Info
  static const String appName = 'GigMatch';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
}
