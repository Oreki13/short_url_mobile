import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
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
  final String baseUrl = 'http://127.0.0.1:3001/v1';

  // Logger instance
  late final LoggerUtil _logger;

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

    // Add interceptors
    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_loggingInterceptor());
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

  // Add authorization token to headers
  void setAuthToken(String token, String userId) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    dio.options.headers['x-control-user'] = userId;
  }

  // Clear authorization token
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
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
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
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
      return await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
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
      return await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }
}
