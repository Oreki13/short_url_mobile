import 'package:equatable/equatable.dart';

/// Entity class for login response
class LoginEntity extends Equatable {
  final String status;
  final String code;
  final String? message;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const LoginEntity({
    required this.status,
    required this.code,
    this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  @override
  List<Object?> get props => [
    status,
    code,
    message,
    accessToken,
    refreshToken,
    expiresIn,
  ];

  /// Check if login was successful
  bool get isSuccess => status == "OK" && code == "LOGIN_SUCCESS";
}
