import 'package:equatable/equatable.dart';

/// Entity class for login response
class LoginEntity extends Equatable {
  final String status;
  final String code;
  final String? message;
  final String token;

  const LoginEntity({
    required this.status,
    required this.code,
    this.message,
    required this.token,
  });

  @override
  List<Object?> get props => [status, code, message, token];

  /// Check if login was successful
  bool get isSuccess => status == "OK" && code == "LOGIN_SUCCESS";
}
