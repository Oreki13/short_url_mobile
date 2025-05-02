import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:short_url_mobile/core/constant/route_constant.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/data/datasources/local/secure_storage_data_local.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';
import 'package:short_url_mobile/dependency.dart' as di;
import 'package:short_url_mobile/domain/repositories/auth_repository.dart';

class DioService {
  // Singleton instance
  static final DioService _instance = DioService._internal();

  // Private constructor
  DioService._internal();

  // Factory constructor to return the singleton instance
  factory DioService() => _instance;

  // The Dio client instance
  late final Dio dio;

  // Base URL for the API
  final String baseUrl = 'http://127.0.0.1:3001/api/v1';

  // Logger instance
  late final LoggerUtil _logger;

  // CSRF Token for secure requests
  String? _csrfToken;

  // Cookie jar to handle cookies
  late final CookieJar _cookieJar;

  // Flag to prevent multiple token refreshes at the same time
  bool _isRefreshing = false;

  // Queue of requests that are waiting for token refresh
  final List<RequestOptions> _pendingRequests = [];

  // Initialize the Dio client with configurations
  void initialize() {
    _logger = di.sl<LoggerUtil>();
    dio = Dio(
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

    // Initialize cookie jar
    _cookieJar = CookieJar();

    // Add interceptors
    dio.interceptors.add(CookieManager(_cookieJar));
    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_loggingInterceptor());
    dio.interceptors.add(_cookieInterceptor());
    dio.interceptors.add(_setCookieInterceptor());
  }

  // Auth interceptor to handle token expired
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) async {
        // Skip token refresh intercept for the refresh-token endpoint itself
        if (response.requestOptions.path.contains('/auth/refresh-token')) {
          return handler.next(response);
        }

        // Skip token refresh intercept for retried requests
        if (response.requestOptions.headers.containsKey('X-Retry-Request')) {
          return handler.next(response);
        }

        // Check if response contains token expired error
        if (response.data is Map<String, dynamic> &&
            response.data['status'] == 'ERROR' &&
            response.data['code'] == 'TOKEN_EXPIRED') {
          _logger.warning(
            'Token expired detected, attempting to refresh token',
          );

          // Try to handle token refresh and retry request
          try {
            final RequestOptions requestOptions = response.requestOptions;

            // Try to refresh token
            final bool refreshSuccess = await _refreshToken();

            if (refreshSuccess) {
              // Retry the original request with new token
              final response = await _retryRequest(requestOptions);
              return handler.resolve(response);
            } else {
              // If token refresh failed, force logout and redirect to login
              await _handleSessionExpired();
              return handler.next(response);
            }
          } catch (e) {
            _logger.error('Failed to refresh token: $e');
            // If refreshing token fails, proceed with the original response
            await _handleSessionExpired();
            return handler.next(response);
          }
        }

        // Normal response handling
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        // Skip token refresh intercept for the refresh-token endpoint itself
        if (error.requestOptions.path.contains('/auth/refresh-token')) {
          return handler.next(error);
        }

        // Skip token refresh intercept for retried requests
        if (error.requestOptions.headers.containsKey('X-Retry-Request')) {
          return handler.next(error);
        }

        // Check if error response contains token expired error
        if (error.response?.data is Map<String, dynamic> &&
            error.response?.data['status'] == 'ERROR' &&
            error.response?.data['code'] == 'TOKEN_EXPIRED') {
          _logger.warning(
            'Token expired error detected, attempting to refresh token',
          );

          // Try to handle token refresh and retry request
          try {
            final RequestOptions requestOptions = error.requestOptions;

            // Try to refresh token
            final bool refreshSuccess = await _refreshToken();

            if (refreshSuccess) {
              // Retry the original request with new token
              final response = await _retryRequest(requestOptions);
              return handler.resolve(response);
            } else {
              // If token refresh failed, force logout and redirect to login
              await _handleSessionExpired();
              return handler.next(error);
            }
          } catch (e) {
            _logger.error('Failed to refresh token: $e');
            // If refreshing token fails, proceed with the original error
            await _handleSessionExpired();
            return handler.next(error);
          }
        }

        // Normal error handling
        return handler.next(error);
      },
    );
  }

  // Logging interceptor for debugging API calls
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          _logger.info('REQUEST[${options.method}] => PATH: ${options.path}');
          _logger.info('REQUEST HEADERS: ${options.headers}');
          _logger.info('REQUEST DATA: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          _logger.info(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          _logger.info('RESPONSE DATA: ${response.data}');
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          _logger.error(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          _logger.error('ERROR MESSAGE: ${error.message}');
        }
        return handler.next(error);
      },
    );
  }

  // Retry the original request with updated token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    _logger.info('Retrying request to: ${requestOptions.path}');

    // Mendapatkan token terbaru dari headers dio (yang seharusnya sudah diperbarui)
    final currentToken = dio.options.headers['Authorization'];
    final currentUserId = dio.options.headers['x-control-user'];

    // Pastikan header request menggunakan token terbaru
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (currentToken != null) {
      headers['Authorization'] = currentToken;
    }
    if (currentUserId != null) {
      headers['x-control-user'] = currentUserId;
    }

    // Tambahkan marker untuk menandai bahwa ini adalah request yang di-retry
    // untuk menghindari infinite loop refresh token
    headers['X-Retry-Request'] = 'true';

    _logger.info('Using updated token for retry request');

    final options = Options(method: requestOptions.method, headers: headers);

    // Gunakan instance dio baru untuk menghindari loop interceptor
    final retryDio = Dio(BaseOptions(baseUrl: baseUrl));

    // Log request yang akan diulang
    _logger.info('Retry request details:');
    _logger.info('- Path: ${requestOptions.path}');
    _logger.info('- Method: ${requestOptions.method}');
    _logger.info('- Headers: ${headers.toString()}');

    try {
      final response = await retryDio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
      );

      _logger.info(
        'Retry request succeeded with status: ${response.statusCode}',
      );
      return response;
    } catch (e) {
      _logger.error('Retry request failed: $e');
      rethrow;
    }
  }

  // Handle case when session is expired and needs to logout and redirect
  Future<void> _handleSessionExpired() async {
    _logger.warning('Session expired, logging out and redirecting to login');

    try {
      // Get auth repository
      final AuthRepository authRepository = di.sl<AuthRepository>();

      // Logout (this should clear tokens)
      await authRepository.logout();

      // Redirect to login screen
      // Since we can't directly access context here, we need to use a different approach
      // You might implement a global navigator key or use a routing service

      // This is a simple approach using GoRouter's static methods
      // You should implement a more robust solution based on your app's architecture
      GoRouter.of(di.navigatorKey.currentContext!).go(RouteConstants.login);
    } catch (e) {
      _logger.error('Error during session expired handling: $e');
    }
  }

  // Logic to refresh token
  Future<bool> _refreshToken() async {
    // If already refreshing, wait until it's done
    if (_isRefreshing) {
      // Wait for the refreshing process to complete
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _isRefreshing;
      });

      // Return true if we have a valid token now
      try {
        final SecureStorageDataLocal secureStorage =
            di.sl<SecureStorageDataLocal>();
        final token = await secureStorage.getAuthToken();
        return token != null && token.isNotEmpty;
      } catch (e) {
        return false;
      }
    }

    _isRefreshing = true;

    try {
      final SharedPreferenceDataLocal sharedPrefs =
          di.sl<SharedPreferenceDataLocal>();
      final SecureStorageDataLocal secureStorage =
          di.sl<SecureStorageDataLocal>();

      // Get refresh token if available
      final refreshToken = await secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.warning('No refresh token available, cannot refresh session');
        return false;
      }

      // Use a separate Dio instance for token refresh to avoid interceptor loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Call refresh token endpoint
      final refreshResponse = await refreshDio.post(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
      );

      if (refreshResponse.statusCode == 200 &&
          refreshResponse.data['status'] == 'OK' &&
          refreshResponse.data['code'] == 'TOKEN_REFRESHED' &&
          refreshResponse.data['data'] != null) {
        // Extract new token
        final data = refreshResponse.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int;

        // Get user ID
        final userId = await sharedPrefs.getUserId();

        // Save new access token
        await secureStorage.cacheAuthToken(newAccessToken);

        // Update dio headers
        setAuthToken(newAccessToken, userId ?? '');

        _logger.info(
          'Token refreshed successfully. Expires in: $expiresIn seconds',
        );
        return true;
      }

      // Check for invalid refresh token
      if (refreshResponse.data['status'] == 'ERROR' &&
          refreshResponse.data['code'] == 'INVALID_REFRESH_TOKEN') {
        _logger.warning(
          'Refresh token is invalid or expired. User will be redirected to login screen.',
        );
        // Handle invalid refresh token by logging out
        await _handleSessionExpired();
        return false;
      }

      _logger.warning(
        'Failed to refresh token. Status: ${refreshResponse.statusCode}, '
        'Response: ${refreshResponse.data}',
      );
      return false;
    } catch (e) {
      _logger.error('Error refreshing token: $e');
      return false;
    } finally {
      _isRefreshing = false;

      // Process any pending requests
      if (_pendingRequests.isNotEmpty) {
        final requests = List<RequestOptions>.from(_pendingRequests);
        _pendingRequests.clear();

        for (final request in requests) {
          _retryRequest(request);
        }
      }
    }
  }

  // Add authorization token to headers and cookies
  void setAuthToken(String token, String userId) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    dio.options.headers['x-control-user'] = userId;

    // Add token to cookies
    final uri = Uri.parse(baseUrl);
    final accessTokenCookie = Cookie('accessToken', token);
    accessTokenCookie.domain = uri.host;
    accessTokenCookie.path = '/';
    accessTokenCookie.expires = DateTime.now().add(
      const Duration(seconds: 7800),
    );
    accessTokenCookie.httpOnly = true; // For security
    accessTokenCookie.sameSite = SameSite.strict; // Optional, adjust as needed
    _cookieJar.saveFromResponse(uri, [accessTokenCookie]);

    _logger.info('Access token set in headers and cookies');
  }

  // Set refresh token in cookies
  void setRefreshTokenCookie(String refreshToken) {
    final uri = Uri.parse(baseUrl);
    final refreshTokenCookie = Cookie('refreshToken', refreshToken);
    refreshTokenCookie.domain = uri.host;
    refreshTokenCookie.path = '/';
    refreshTokenCookie.httpOnly = true;
    refreshTokenCookie.sameSite = SameSite.strict; // Optional, adjust as needed
    refreshTokenCookie.expires = DateTime.now().add(
      const Duration(seconds: 604800),
    );
    _cookieJar.saveFromResponse(uri, [refreshTokenCookie]);

    _logger.info('Refresh token set in cookies');
  }

  // Clear authorization token from headers and cookies
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
    dio.options.headers.remove('x-control-user');

    // Clear cookies
    _cookieJar.deleteAll();

    // Clear CSRF token as well
    _csrfToken = null;

    _logger.info('Auth tokens cleared from headers and cookies');
  }

  // Helper method for GET requests
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await dio.get(
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
      final csrfToken = await _ensureCsrfToken();

      // Create options with CSRF token header
      final Options requestOptions = options ?? Options();
      requestOptions.headers = requestOptions.headers ?? {};

      if (csrfToken != null) {
        requestOptions.headers!['X-CSRF-Token'] = csrfToken;
      }

      return await dio.post(
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
      final csrfToken = await _ensureCsrfToken();

      // Create options with CSRF token header
      final Options requestOptions = options ?? Options();
      requestOptions.headers = requestOptions.headers ?? {};
      if (csrfToken != null) {
        requestOptions.headers!['X-CSRF-Token'] = csrfToken;
      }

      return await dio.put(
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
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      // Get CSRF token
      final csrfToken = await _ensureCsrfToken();

      // Create options with CSRF token header
      final Options requestOptions = options ?? Options();
      requestOptions.headers = requestOptions.headers ?? {};
      if (csrfToken != null) {
        requestOptions.headers!['X-CSRF-Token'] = csrfToken;
      }

      return await dio.delete(
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

  // Get CSRF token from the server
  Future<String?> _fetchCsrfToken() async {
    try {
      _logger.info('Fetching CSRF token');
      final SecureStorageDataLocal secureStorage =
          di.sl<SecureStorageDataLocal>();
      final token = await secureStorage.getAuthToken();
      final SharedPreferenceDataLocal sharedPrefs =
          di.sl<SharedPreferenceDataLocal>();
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

      final response = await csrfDio.get('/csrf-token');

      if (response.statusCode == 200 &&
          response.data['status'] == 'OK' &&
          response.data['code'] == 'CSRF_TOKEN_GENERATED') {
        final csrfToken = response.data['data']['csrfToken'] as String;
        _logger.info('CSRF token fetched successfully');

        // Store for future use
        _csrfToken = csrfToken;
        return csrfToken;
      } else {
        _logger.warning('Failed to fetch CSRF token: ${response.data}');
        return null;
      }
    } catch (e) {
      _logger.error('Error fetching CSRF token: $e');
      return null;
    }
  }

  // Ensure CSRF token is present
  Future<String?> _ensureCsrfToken() async {
    // If we already have a token, use it
    if (_csrfToken != null && _csrfToken!.isNotEmpty) {
      return _csrfToken;
    }

    // Otherwise fetch a new one
    return await _fetchCsrfToken();
  }

  // Cookie check interceptor - verifies cookies before each request
  Interceptor _cookieInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Skip cookie check for login, logout, and refresh token endpoints
          final String path = options.path.toLowerCase();
          if (path.contains('/auth/login') ||
              path.contains('/auth/logout') ||
              path.contains('/auth/refresh-token') ||
              path.contains('/csrf-token')) {
            _logger.info(
              'Skipping cookie check for auth endpoint: ${options.path}',
            );
            return handler.next(options);
          }

          // Get cookies from the cookie jar
          final uri = Uri.parse(baseUrl);
          final cookies = await _cookieJar.loadForRequest(uri);

          // Check if accessToken cookie exists
          final hasAccessTokenCookie = cookies.any(
            (cookie) => cookie.name == 'accessToken',
          );

          if (!hasAccessTokenCookie) {
            _logger.warning(
              'No access token cookie found, checking secure storage',
            );

            // Check if token exists in secure storage
            final SecureStorageDataLocal secureStorage =
                di.sl<SecureStorageDataLocal>();
            final token = await secureStorage.getAuthToken();
            final SharedPreferenceDataLocal sharedPrefs =
                di.sl<SharedPreferenceDataLocal>();
            final userId = await sharedPrefs.getUserId();

            if (token != null &&
                token.isNotEmpty &&
                userId != null &&
                userId.isNotEmpty) {
              // Token exists in secure storage, add it to cookies
              _logger.info('Token found in secure storage, adding to cookies');
              setAuthToken(token, userId);

              // For remembered users, also check refresh token
              final rememberMe = await sharedPrefs.getRememberMe();
              if (rememberMe) {
                final refreshToken = await secureStorage.getRefreshToken();
                if (refreshToken != null && refreshToken.isNotEmpty) {
                  setRefreshTokenCookie(refreshToken);
                }
              }

              return handler.next(options);
            } else {
              // No token in secure storage either, redirect to login
              _logger.warning('No token available, redirecting to login');
              await _handleSessionExpired();

              // Return error response to cancel the request
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'No authentication token available',
                  type: DioExceptionType.cancel,
                ),
              );
            }
          }
        } catch (e) {
          _logger.error('Error in cookie interceptor: $e');
        }

        // Continue with the request
        return handler.next(options);
      },
    );
  }

  // Interceptor to handle Set-Cookie headers from API responses
  Interceptor _setCookieInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) async {
        try {
          // Check if response has Set-Cookie headers
          final headers = response.headers;
          final setCookieValues = headers.map['set-cookie'];

          if (setCookieValues != null && setCookieValues.isNotEmpty) {
            _logger.info('Found Set-Cookie headers in response');

            // Parse cookies from headers
            final uri = Uri.parse(baseUrl);
            final cookies = <Cookie>[];

            for (final cookieStr in setCookieValues) {
              try {
                // Basic cookie parsing (you may need a more robust parser for complex cookies)
                final parts = cookieStr.split(';');
                if (parts.isNotEmpty && parts[0].contains('=')) {
                  final nameValue = parts[0].split('=');
                  if (nameValue.length == 2) {
                    final name = nameValue[0].trim();
                    final value = nameValue[1].trim();

                    final cookie = Cookie(name, value);

                    // Parse additional cookie attributes
                    for (var i = 1; i < parts.length; i++) {
                      final attribute = parts[i].trim();
                      final attributeLower = attribute.toLowerCase();

                      if (attributeLower.startsWith('expires=')) {
                        try {
                          // Get full expires date string with correct casing
                          final dateStr = attribute.substring(8).trim();

                          // Manually parse the date with proper formatting
                          // The format is typically: "Fri, 02 May 2025 10:54:59 GMT"
                          _logger.info('Parsing cookie expiry date: $dateStr');

                          try {
                            // Use DateTime.parse with RFC1123 format (HTTP date format)
                            final expires = DateTime.parse(dateStr);
                            cookie.expires = expires;
                            _logger.info(
                              'Successfully parsed cookie expiry: $expires',
                            );
                          } catch (parseError) {
                            // If standard parsing fails, try manual parsing
                            _logger.warning(
                              'Standard date parsing failed, trying manual: $parseError',
                            );

                            // Try an alternative date format parser
                            try {
                              // Split the date parts
                              final parts = dateStr.split(' ');
                              if (parts.length >= 5) {
                                // Extract components: day, date, month, year, time
                                final day = parts[0].replaceAll(
                                  ',',
                                  '',
                                ); // "Fri,"
                                final date = int.parse(parts[1]); // "02"

                                // Convert month name to number
                                int month;
                                final monthName = parts[2].toLowerCase();
                                switch (monthName) {
                                  case 'jan':
                                  case 'january':
                                    month = 1;
                                    break;
                                  case 'feb':
                                  case 'february':
                                    month = 2;
                                    break;
                                  case 'mar':
                                  case 'march':
                                    month = 3;
                                    break;
                                  case 'apr':
                                  case 'april':
                                    month = 4;
                                    break;
                                  case 'may':
                                    month = 5;
                                    break;
                                  case 'jun':
                                  case 'june':
                                    month = 6;
                                    break;
                                  case 'jul':
                                  case 'july':
                                    month = 7;
                                    break;
                                  case 'aug':
                                  case 'august':
                                    month = 8;
                                    break;
                                  case 'sep':
                                  case 'september':
                                    month = 9;
                                    break;
                                  case 'oct':
                                  case 'october':
                                    month = 10;
                                    break;
                                  case 'nov':
                                  case 'november':
                                    month = 11;
                                    break;
                                  case 'dec':
                                  case 'december':
                                    month = 12;
                                    break;
                                  default:
                                    throw FormatException(
                                      'Invalid month: $monthName',
                                    );
                                }

                                final year = int.parse(parts[3]); // "2025"

                                // Parse time (HH:MM:SS)
                                final timeComponents = parts[4].split(':');
                                final hour = int.parse(timeComponents[0]);
                                final minute = int.parse(timeComponents[1]);
                                final second = int.parse(timeComponents[2]);

                                // Create DateTime
                                final expires = DateTime.utc(
                                  year,
                                  month,
                                  date,
                                  hour,
                                  minute,
                                  second,
                                );
                                cookie.expires = expires;
                                _logger.info(
                                  'Successfully parsed cookie expiry with manual method: $expires',
                                );
                              } else {
                                throw FormatException(
                                  'Date format not recognized: $dateStr',
                                );
                              }
                            } catch (manualError) {
                              _logger.error(
                                'Error in manual date parsing: $manualError for date: $dateStr',
                              );
                            }
                          }
                        } catch (e) {
                          _logger.warning('Failed to parse cookie expiry: $e');
                        }
                      } else if (attributeLower.startsWith('max-age=')) {
                        try {
                          final maxAge = int.parse(attributeLower.substring(8));
                          cookie.expires = DateTime.now().add(
                            Duration(seconds: maxAge),
                          );
                        } catch (e) {
                          _logger.warning('Failed to parse cookie max-age: $e');
                        }
                      } else if (attributeLower.startsWith('domain=')) {
                        cookie.domain = attribute.substring(7);
                      } else if (attributeLower.startsWith('path=')) {
                        cookie.path = attribute.substring(5);
                      } else if (attributeLower == 'secure') {
                        cookie.secure = true;
                      } else if (attributeLower == 'httponly') {
                        cookie.httpOnly = true;
                      } else if (attributeLower.startsWith('samesite=')) {
                        final sameSiteStr = attributeLower.substring(9);
                        if (sameSiteStr == 'strict') {
                          cookie.sameSite = SameSite.strict;
                        } else if (sameSiteStr == 'lax') {
                          cookie.sameSite = SameSite.lax;
                        } else if (sameSiteStr == 'none') {
                          cookie.sameSite = SameSite.none;
                        }
                      }
                    }

                    cookies.add(cookie);

                    // Special handling for auth tokens
                    if (name == 'accessToken') {
                      final SharedPreferenceDataLocal sharedPrefs =
                          di.sl<SharedPreferenceDataLocal>();
                      final userId = await sharedPrefs.getUserId() ?? '';

                      // Update the auth token in the dio headers
                      setAuthToken(value, userId);

                      // Cache the token in secure storage
                      final SecureStorageDataLocal secureStorage =
                          di.sl<SecureStorageDataLocal>();
                      await secureStorage.cacheAuthToken(value);

                      _logger.info('Saved access token from Set-Cookie header');
                    } else if (name == 'refreshToken') {
                      // Cache the refresh token in secure storage
                      final SecureStorageDataLocal secureStorage =
                          di.sl<SecureStorageDataLocal>();
                      await secureStorage.cacheRefreshToken(value);

                      _logger.info(
                        'Saved refresh token from Set-Cookie header',
                      );
                    }
                  }
                }
              } catch (e) {
                _logger.error('Error parsing cookie: $e');
              }
            }

            // Save parsed cookies to cookie jar
            if (cookies.isNotEmpty) {
              _cookieJar.saveFromResponse(uri, cookies);
              _logger.info('Saved ${cookies.length} cookies to cookie jar');
            }
          }
        } catch (e) {
          _logger.error('Error in Set-Cookie interceptor: $e');
        }

        // Continue with response handling
        return handler.next(response);
      },
    );
  }
}
