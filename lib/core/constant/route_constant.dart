class RouteConstants {
  // Root routes
  static const String root = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';

  // Dashboard routes
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';

  // URL management
  static const String urlList = '/urls';
  static const String urlCreate = '/urls/create';
  static const String urlDetails = '/urls/:id';

  // Settings
  static const String settings = '/settings';
  static const String changePassword = '/settings/change-password';

  // Helper method for URL details path with parameter
  static String urlDetailsPath(String id) => '/urls/$id';
}
