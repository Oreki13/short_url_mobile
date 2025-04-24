import 'package:short_url_mobile/domain/entities/login_entity.dart';

class LoginModel extends LoginEntity {
  const LoginModel({
    required super.status,
    required super.code,
    super.message,
    required super.accessToken,
    required super.refreshToken,
    required super.expiresIn,
  });

  /// Factory method to create a LoginModel from JSON
  factory LoginModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginModel(
      status: json['status'] as String,
      code: json['code'] as String,
      message: json['message'] as String?,
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresIn: data['expires_in'] as int,
    );
  }

  /// Convert LoginModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'code': code,
      'message': message,
      'data': {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
      },
    };
  }
}
