import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/data/datasources/local/secure_storage_data_local.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';

class AppCookieManager {
  final CookieJar cookieJar;
  final LoggerUtil logger;
  final SecureStorageDataLocal secureStorage;
  final SharedPreferenceDataLocal sharedPrefs;
  final String baseUrl;

  AppCookieManager({
    required this.cookieJar,
    required this.logger,
    required this.secureStorage,
    required this.sharedPrefs,
    required this.baseUrl,
  });

  // Helper method to safely update cookies and avoid duplicates
  Future<void> _safelyUpdateCookies(List<Cookie> newCookies) async {
    final uri = Uri.parse(baseUrl);

    try {
      // Get existing cookies
      final existingCookies = await cookieJar.loadForRequest(uri);

      // Create a map to ensure uniqueness
      final cookieMap = <String, Cookie>{};

      // Add existing cookies that won't be replaced
      for (var cookie in existingCookies) {
        if (!newCookies.any((c) => c.name == cookie.name)) {
          cookieMap[cookie.name] = cookie;
        }
      }

      // Add all new cookies
      for (var cookie in newCookies) {
        cookieMap[cookie.name] = cookie;
      }

      // Convert to list
      final updatedCookies = cookieMap.values.toList();

      // Clear and save
      await cookieJar.deleteAll();
      if (updatedCookies.isNotEmpty) {
        await cookieJar.saveFromResponse(uri, updatedCookies);
      }
    } catch (e) {
      logger.error('Error updating cookies: $e');
    }
  }

  // Set auth token to cookies
  Future<void> setAuthToken(String token, String userId) async {
    final uri = Uri.parse(baseUrl);
    final accessTokenCookie = Cookie('accessToken', token);
    accessTokenCookie.domain = uri.host;
    accessTokenCookie.path = '/';
    accessTokenCookie.expires = DateTime.now().add(
      const Duration(seconds: 7800),
    );
    accessTokenCookie.httpOnly = true;
    accessTokenCookie.sameSite = SameSite.strict;

    await _safelyUpdateCookies([accessTokenCookie]);
    logger.info('Access token set in cookies');
  }

  // Set refresh token in cookies
  Future<void> setRefreshTokenCookie(String refreshToken) async {
    final uri = Uri.parse(baseUrl);
    final refreshTokenCookie = Cookie('refreshToken', refreshToken);
    refreshTokenCookie.domain = uri.host;
    refreshTokenCookie.path = '/';
    refreshTokenCookie.httpOnly = true;
    refreshTokenCookie.sameSite = SameSite.strict;
    refreshTokenCookie.expires = DateTime.now().add(
      const Duration(seconds: 604800),
    );

    await _safelyUpdateCookies([refreshTokenCookie]);
    logger.info('Refresh token set in cookies');
  }

  // Clear cookies
  void clearCookies() {
    cookieJar.deleteAll();
    logger.info('Cookies cleared');
  }

  // Cookie check interceptor - verifies cookies before each request
  Interceptor cookieInterceptor(Dio dio) {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Add a marker to avoid infinite loops with setCookieInterceptor
          if (options.headers.containsKey('X-Cookie-Check-Done')) {
            return handler.next(options);
          }
          options.headers['X-Cookie-Check-Done'] = 'true';

          // Skip cookie check for auth endpoints and CSRF token
          final String path = options.path.toLowerCase();
          if (path.contains('/auth/login') ||
              path.contains('/auth/logout') ||
              path.contains('/auth/refresh-token') ||
              path.contains('/csrf-token')) {
            return handler.next(options);
          }

          // Get cookies from the cookie jar
          final uri = Uri.parse(baseUrl);
          final cookies = await cookieJar.loadForRequest(uri);

          // Check if accessToken cookie exists
          final accessTokenCookie = cookies.firstWhere(
            (cookie) => cookie.name == 'accessToken',
            orElse: () => Cookie('', ''),
          );

          final bool hasValidAccessToken =
              accessTokenCookie.name.isNotEmpty &&
              accessTokenCookie.value.isNotEmpty;

          if (!hasValidAccessToken) {
            // Check if token exists in secure storage
            final token = await secureStorage.getAuthToken();
            final userId = await sharedPrefs.getUserId();

            if (token != null &&
                token.isNotEmpty &&
                userId != null &&
                userId.isNotEmpty) {
              // Token exists in secure storage, add it to cookies
              await setAuthToken(token, userId);

              // Update dio headers too
              dio.options.headers['Authorization'] = 'Bearer $token';
              dio.options.headers['x-control-user'] = userId;

              // For remembered users, also check refresh token
              final rememberMe = await sharedPrefs.getRememberMe();
              if (rememberMe) {
                final refreshToken = await secureStorage.getRefreshToken();
                if (refreshToken != null && refreshToken.isNotEmpty) {
                  await setRefreshTokenCookie(refreshToken);
                }
              }

              return handler.next(options);
            }
          }
        } catch (e) {
          logger.error('Error in cookie interceptor: $e');
        }

        // Continue with the request
        return handler.next(options);
      },
    );
  }

  // Parse cookie from string
  Cookie _parseCookieString(String cookieStr) {
    final parts = cookieStr.split(';');
    if (parts.isEmpty || !parts[0].contains('=')) {
      throw FormatException('Invalid cookie format');
    }

    final nameValue = parts[0].split('=');
    if (nameValue.length != 2) {
      throw FormatException('Invalid name-value format');
    }

    final name = nameValue[0].trim();
    final value = nameValue[1].trim();

    final cookie = Cookie(name, value);

    // Parse cookie attributes
    for (var i = 1; i < parts.length; i++) {
      final attribute = parts[i].trim();
      final attributeLower = attribute.toLowerCase();

      if (attributeLower.startsWith('expires=')) {
        try {
          final dateStr = attribute.substring(8).trim();
          try {
            cookie.expires = DateTime.parse(dateStr);
          } catch (e) {
            _parseExpireDateManually(dateStr, cookie);
          }
        } catch (e) {
          logger.warning('Failed to parse cookie expiry');
        }
      } else if (attributeLower.startsWith('max-age=')) {
        try {
          final maxAge = int.parse(attributeLower.substring(8));
          cookie.expires = DateTime.now().add(Duration(seconds: maxAge));
        } catch (e) {
          // Ignore parsing errors
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

    return cookie;
  }

  // Process cookies from Set-Cookie headers
  Future<void> _processCookies(
    List<String> cookieStrings,
    Uri uri,
    Dio dio,
  ) async {
    final cookies = <Cookie>[];

    for (final cookieStr in cookieStrings) {
      try {
        final cookie = _parseCookieString(cookieStr);

        // Handle special cookies
        if (cookie.name == 'accessToken') {
          final userId = await sharedPrefs.getUserId() ?? '';
          dio.options.headers['Authorization'] = 'Bearer ${cookie.value}';
          dio.options.headers['x-control-user'] = userId;
          await secureStorage.cacheAuthToken(cookie.value);
        } else if (cookie.name == 'refreshToken') {
          await secureStorage.cacheRefreshToken(cookie.value);
        }

        cookies.add(cookie);
      } catch (e) {
        logger.error('Error parsing cookie: $e');
      }
    }

    if (cookies.isNotEmpty) {
      await _safelyUpdateCookies(cookies);
    }
  }

  // Interceptor to handle Set-Cookie headers from API responses
  Interceptor setCookieInterceptor(Dio dio) {
    return InterceptorsWrapper(
      onResponse: (response, handler) async {
        try {
          final headers = response.headers;
          final setCookieValues = headers.map['set-cookie'];

          if (setCookieValues != null && setCookieValues.isNotEmpty) {
            final uri = Uri.parse(baseUrl);
            await _processCookies(setCookieValues, uri, dio);
          }
        } catch (e) {
          logger.error('Error in Set-Cookie interceptor: $e');
        }

        return handler.next(response);
      },
    );
  }

  // Helper method to manually parse cookie expiration dates
  void _parseExpireDateManually(String dateStr, Cookie cookie) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length >= 5) {
        // Extract components: date, month, year, time
        final date = int.parse(parts[1]);

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
            throw FormatException('Invalid month');
        }

        final year = int.parse(parts[3]);

        // Parse time
        final timeComponents = parts[4].split(':');
        final hour = int.parse(timeComponents[0]);
        final minute = int.parse(timeComponents[1]);
        final second = int.parse(timeComponents[2]);

        // Create DateTime
        final expires = DateTime.utc(year, month, date, hour, minute, second);
        cookie.expires = expires;
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }
}
