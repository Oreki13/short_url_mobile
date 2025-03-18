import 'package:short_url_mobile/domain/entities/login_entity.dart';

class LoginModel extends LoginEntity {
  const LoginModel({
    required super.status,
    required super.code,
    super.message,
    required super.token,
  });

  /// Factory method to create a LoginModel from JSON
  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      status: json['status'] as String,
      code: json['code'] as String,
      message: json['message'] as String?,
      token: json['data'] as String, // JWT token is in 'data' field
    );
  }

  /// Convert LoginModel to JSON
  Map<String, dynamic> toJson() {
    return {'status': status, 'code': code, 'message': message, 'data': token};
  }
}
