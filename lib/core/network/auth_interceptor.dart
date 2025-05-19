import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:short_url_mobile/core/constant/route_constant.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/data/datasources/local/secure_storage_data_local.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';
import 'package:short_url_mobile/dependency.dart' as di;
import 'package:short_url_mobile/domain/repositories/auth_repository.dart';

class AuthInterceptor {
  final LoggerUtil logger;
  final SecureStorageDataLocal secureStorage;
  final SharedPreferenceDataLocal sharedPrefs;
  final String baseUrl;
  final Dio dio;

  // Flag to prevent multiple token refreshes at the same time
  bool _isRefreshing = false;

  // Queue of requests that are waiting for token refresh
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor({
    required this.logger,
    required this.secureStorage,
    required this.sharedPrefs,
    required this.baseUrl,
    required this.dio,
  });

  // Auth interceptor to handle token expired
  Interceptor authInterceptor() {
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
          logger.warning('Token expired detected, attempting to refresh token');

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
            logger.error('Failed to refresh token: $e');
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
          logger.warning(
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
            logger.error('Failed to refresh token: $e');
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

  // Retry the original request with updated token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    logger.info('Retrying request to: ${requestOptions.path}');

    // Get the current token from headers (should be updated)
    final currentToken = dio.options.headers['Authorization'];
    final currentUserId = dio.options.headers['x-control-user'];

    // Update request headers with latest tokens
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (currentToken != null) {
      headers['Authorization'] = currentToken;
    }
    if (currentUserId != null) {
      headers['x-control-user'] = currentUserId;
    }

    // Add marker to prevent infinite loop
    headers['X-Retry-Request'] = 'true';

    logger.info('Using updated token for retry request');

    final options = Options(method: requestOptions.method, headers: headers);

    // Use a new Dio instance to avoid interceptor loops
    final retryDio = Dio(BaseOptions(baseUrl: baseUrl));

    // Log request details
    logger.info('Retry request details:');
    logger.info('- Path: ${requestOptions.path}');
    logger.info('- Method: ${requestOptions.method}');
    logger.info('- Headers: ${headers.toString()}');

    try {
      final response = await retryDio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
      );

      logger.info(
        'Retry request succeeded with status: ${response.statusCode}',
      );
      return response;
    } catch (e) {
      logger.error('Retry request failed: $e');
      rethrow;
    }
  }

  // Handle case when session is expired and needs to logout and redirect
  Future<void> _handleSessionExpired() async {
    logger.warning('Session expired, logging out and redirecting to login');

    try {
      // Get auth repository
      final AuthRepository authRepository = di.sl<AuthRepository>();

      // Logout (this should clear tokens)
      await authRepository.logout();

      // Redirect to login screen
      GoRouter.of(di.navigatorKey.currentContext!).go(RouteConstants.login);
    } catch (e) {
      logger.error('Error during session expired handling: $e');
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
        final token = await secureStorage.getAuthToken();
        return token != null && token.isNotEmpty;
      } catch (e) {
        return false;
      }
    }

    _isRefreshing = true;

    try {
      // Get refresh token if available
      final refreshToken = await secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        logger.warning('No refresh token available, cannot refresh session');
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
        dio.options.headers['Authorization'] = 'Bearer $newAccessToken';
        if (userId != null) {
          dio.options.headers['x-control-user'] = userId;
        }

        logger.info(
          'Token refreshed successfully. Expires in: $expiresIn seconds',
        );
        return true;
      }

      // Check for invalid refresh token
      if (refreshResponse.data['status'] == 'ERROR' &&
          refreshResponse.data['code'] == 'INVALID_REFRESH_TOKEN') {
        logger.warning(
          'Refresh token is invalid or expired. User will be redirected to login screen.',
        );
        // Handle invalid refresh token by logging out
        await _handleSessionExpired();
        return false;
      }

      logger.warning(
        'Failed to refresh token. Status: ${refreshResponse.statusCode}, '
        'Response: ${refreshResponse.data}',
      );
      return false;
    } catch (e) {
      logger.error('Error refreshing token: $e');
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
}
