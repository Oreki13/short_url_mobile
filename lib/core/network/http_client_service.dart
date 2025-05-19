import 'package:dio/dio.dart';

/// Interface for HTTP client services
abstract class HttpClientService {
  /// The Dio client instance for direct access when needed
  Dio get dio;

  /// Sends a GET request to the specified URL
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Sends a POST request to the specified URL
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Sends a PUT request to the specified URL
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Sends a DELETE request to the specified URL
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Sets the authentication token for future requests
  Future<void> setAuthToken(String token, String userId);

  /// Sets the refresh token in cookies
  Future<void> setRefreshTokenCookie(String refreshToken);

  /// Clears the authentication token and related cookies
  void clearAuthToken();

  /// Initialize the service with required configurations
  void initialize();
}
