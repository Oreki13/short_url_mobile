import 'package:dio/dio.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/core/network/cookie_manager.dart';
import 'package:short_url_mobile/data/datasources/local/secure_storage_data_local.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';

class CsrfTokenManager {
  final LoggerUtil logger;
  final SecureStorageDataLocal secureStorage;
  final SharedPreferenceDataLocal sharedPrefs;
  final AppCookieManager cookieManager;

  // CSRF Token for secure requests
  String? _csrfToken;

  CsrfTokenManager({
    required this.logger,
    required this.secureStorage,
    required this.sharedPrefs,
    required this.cookieManager,
  });

  // Get CSRF token from the server
  Future<String?> fetchCsrfToken() async {
    try {
      logger.info('Fetching CSRF token');

      final token = await secureStorage.getAuthToken();
      final userId = await sharedPrefs.getUserId();

      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      if (userId != null && userId.isNotEmpty) {
        headers['x-control-user'] = userId;
      }

      // Create separate Dio instance for CSRF token request to avoid interceptors
      final csrfDio = Dio(
        BaseOptions(baseUrl: "http://127.0.0.1:3001", headers: headers),
      );

      // Add set-cookie interceptor to handle cookies in response
      csrfDio.interceptors.add(cookieManager.setCookieInterceptor(csrfDio));

      final response = await csrfDio.get('/csrf-token');

      if (response.statusCode == 200 &&
          response.data['status'] == 'OK' &&
          response.data['code'] == 'CSRF_TOKEN_GENERATED') {
        final csrfToken = response.data['data']['csrfToken'] as String;
        logger.info('CSRF token fetched successfully');

        // Store for future use
        _csrfToken = csrfToken;
        return csrfToken;
      } else {
        logger.warning('Failed to fetch CSRF token: ${response.data}');
        return null;
      }
    } catch (e) {
      logger.error('Error fetching CSRF token: $e');
      return null;
    }
  }

  // Ensure CSRF token is present
  Future<String?> ensureCsrfToken() async {
    // If we already have a token, use it
    if (_csrfToken != null && _csrfToken!.isNotEmpty) {
      return _csrfToken;
    }

    // Otherwise fetch a new one
    return await fetchCsrfToken();
  }

  // Clear CSRF token
  void clearCsrfToken() {
    _csrfToken = null;
    logger.info('CSRF token cleared');
  }
}
