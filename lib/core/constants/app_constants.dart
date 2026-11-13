abstract class AppConstants {
  static const String appName = 'LogiFlow';
  static const String appVersion = '1.0.0';
  static const String currency = 'UZS';
  static const String currencyUsd = 'USD';
  
  // Storage Keys
  static const String tokenKey = 'logiflow_auth_token';
  static const String refreshTokenKey = 'logiflow_refresh_token';
  static const String userRoleKey = 'logiflow_user_role';
  static const String userProfileKey = 'logiflow_user_profile';
  static const String themeModeKey = 'logiflow_theme_mode';
  static const String languageKey = 'logiflow_language';
}


abstract class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8000/api/v1/ws',
  );
  static const String osrmUrl = String.fromEnvironment(
    'OSRM_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  // Auth
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';

  // Shipments & Loads
  static const String loads = '/loads';
  static const String loadDetail = '/loads/{id}';
  static const String createLoad = '/loads';
  static const String loadBids = '/loads/{id}/bids';
  static const String submitBid = '/loads/{id}/bids';
  static const String acceptBid = '/loads/{id}/bids/{bidId}/accept';
  static const String updateLoadStatus = '/loads/{id}/status';

  // Escrow & Wallet
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String fundEscrow = '/escrow/fund';
  static const String releaseEscrow = '/escrow/release';

  // Tracking & POD
  static const String tracking = '/tracking/{shipmentId}';
  static const String submitPod = '/shipments/{shipmentId}/pod';

  // Chat
  static const String chatChannels = '/chat/channels';
  static const String chatMessages = '/chat/channels/{channelId}/messages';
}
