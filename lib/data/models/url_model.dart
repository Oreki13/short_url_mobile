import 'package:short_url_mobile/domain/entities/url_entity.dart';

class UrlModel extends UrlEntity {
  const UrlModel({
    required super.id,
    required super.title,
    required super.path,
    required super.countClicks,
    required super.createdAt,
    required super.destination,
    required super.updatedAt,
    required UserModel super.user,
  });

  factory UrlModel.fromJson(Map<String, dynamic> json) {
    return UrlModel(
      id: json['id'] as String,
      title: json['title'] as String,
      path: json['path'] as String,
      countClicks: json['count_clicks'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      destination: json['destination'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Factory untuk membuat model dari respons API saat membuat URL baru
  /// Respons dari endpoint ini memiliki format yang lebih sederhana
  factory UrlModel.fromCreateResponse(Map<String, dynamic> json) {
    // Gunakan nilai default atau dummy untuk field yang tidak ada dalam respons
    return UrlModel(
      id: json['id'] as String,
      title: json['title'] as String,
      path: json['path'] as String,
      countClicks: 0, // Default untuk URL baru
      createdAt: DateTime.now(), // Gunakan waktu saat ini
      destination: json['destination'] as String,
      updatedAt: DateTime.now(), // Gunakan waktu saat ini
      user: const UserModel(id: '0', name: 'current_user'), // Dummy user
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'count_clicks': countClicks,
      'createdAt': createdAt.toIso8601String(),
      'destination': destination,
      'updatedAt': updatedAt.toIso8601String(),
      'user': (user as UserModel).toJson(),
    };
  }
}

class UserModel extends UserEntity {
  const UserModel({required super.id, required super.name});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
