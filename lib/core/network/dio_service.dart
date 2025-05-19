import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/core/network/auth_interceptor.dart';
import 'package:short_url_mobile/core/network/cookie_manager.dart';
import 'package:short_url_mobile/core/network/csrf_token_manager.dart';
import 'package:short_url_mobile/core/network/http_client_service.dart';
import 'package:short_url_mobile/core/network/logging_interceptor.dart';
import 'package:short_url_mobile/data/datasources/local/secure_storage_data_local.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';
import 'package:short_url_mobile/dependency.dart' as di;

class DioService implements HttpClientService {
  // Singleton instance
  static final DioService _instance = DioService._internal();

  // Private constructor
  DioService._internal();

  // Factory constructor to return the singleton instance
  factory DioService() => _instance;

  // The Dio client instance
  late final Dio _dioInstance;

  // Base URL for the API
  final String baseUrl = 'http://127.0.0.1:3001/api/v1';

  @override
  Dio get dio => _dioInstance;

  // Helper services
  late final LoggerUtil _logger;
  late final CookieJar _cookieJar;
  late final AppCookieManager _cookieManager;
  late final AuthInterceptor _authInterceptor;
  late final LoggingInterceptor _loggingInterceptor;
  late final CsrfTokenManager _csrfTokenManager;

  // Initialize the Dio client with configurations
  @override
  void initialize() {
    _logger = di.sl<LoggerUtil>();

    _dioInstance = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
        sendTimeout: const Duration(milliseconds: 30000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Initialize cookie jar with persistence disabled to avoid storage-related duplication issues
    _cookieJar = CookieJar(ignoreExpires: false);

    // Initialize helpers with dependencies
    final SecureStorageDataLocal secureStorage =
        di.sl<SecureStorageDataLocal>();
    final SharedPreferenceDataLocal sharedPrefs =
        di.sl<SharedPreferenceDataLocal>();

    _cookieManager = AppCookieManager(
      cookieJar: _cookieJar,
      logger: _logger,
      secureStorage: secureStorage,
      sharedPrefs: sharedPrefs,
      baseUrl: baseUrl,
    );

    _authInterceptor = AuthInterceptor(
      logger: _logger,
      secureStorage: secureStorage,
      sharedPrefs: sharedPrefs,
      baseUrl: baseUrl,
      dio: _dioInstance,
    );

    _loggingInterceptor = LoggingInterceptor(logger: _logger);

    _csrfTokenManager = CsrfTokenManager(
      logger: _logger,
      secureStorage: secureStorage,
      sharedPrefs: sharedPrefs,
      cookieManager: _cookieManager,
    );

    // Add interceptors in the correct order
    _dioInstance.interceptors.add(_loggingInterceptor as Interceptor);
    _dioInstance.interceptors.add(
      _cookieManager.cookieInterceptor(_dioInstance),
    );
    _dioInstance.interceptors.add(
      _cookieManager.setCookieInterceptor(_dioInstance),
    );
    _dioInstance.interceptors.add(CookieManager(_cookieJar));
    _dioInstance.interceptors.add(_authInterceptor.authInterceptor());
  }

  // Add authorization token to headers
  @override
  Future<void> setAuthToken(String token, String userId) async {
    _dioInstance.options.headers['Authorization'] = 'Bearer $token';
    _dioInstance.options.headers['x-control-user'] = userId;

    // Also set in cookies
    await _cookieManager.setAuthToken(token, userId);

    _logger.info('Access token set in headers and cookies');
  }

  // Set refresh token in cookies
  @override
  Future<void> setRefreshTokenCookie(String refreshToken) async {
    await _cookieManager.setRefreshTokenCookie(refreshToken);
  }

  // Clear authorization token from headers and cookies
  @override
  void clearAuthToken() {
    _dioInstance.options.headers.remove('Authorization');
    _dioInstance.options.headers.remove('x-control-user');

    // Clear cookies and CSRF token
    _cookieManager.clearCookies();
    _csrfTokenManager.clearCsrfToken();

    _logger.info('Auth tokens cleared from headers and cookies');
  }

  // Helper method for GET requests
  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dioInstance.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper method for POST requests
  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Get CSRF token
      String? csrfToken;
      if (!path.contains('/auth/login')) {
        csrfToken = await _csrfTokenManager.ensureCsrfToken();
      }

      // Create options with CSRF token header
      final Options requestOptions = options ?? Options();
      requestOptions.headers = requestOptions.headers ?? {};

      if (csrfToken != null) {
        requestOptions.headers!['X-CSRF-Token'] = csrfToken;
      }

      return await _dioInstance.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper method for PUT requests
  @override
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Get CSRF token
      String? csrfToken;
      if (!path.contains('/auth/login')) {
        csrfToken = await _csrfTokenManager.ensureCsrfToken();
      }

      // Create options with CSRF token header
      final Options requestOptions = options ?? Options();
      requestOptions.headers = requestOptions.headers ?? {};
      if (csrfToken != null) {
        requestOptions.headers!['X-CSRF-Token'] = csrfToken;
      }

      return await _dioInstance.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper method for DELETE requests
  @override
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      String? csrfToken;
      if (!path.contains('/auth/login')) {
        csrfToken = await _csrfTokenManager.ensureCsrfToken();
      }
      // Create options with CSRF token header
      final Options requestOptions = options ?? Options();
      requestOptions.headers = requestOptions.headers ?? {};
      if (csrfToken != null) {
        requestOptions.headers!['X-CSRF-Token'] = csrfToken;
      }

      return await _dioInstance.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }
}
