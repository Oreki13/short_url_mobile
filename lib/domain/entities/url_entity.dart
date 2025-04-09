import 'package:equatable/equatable.dart';

class UrlEntity extends Equatable {
  final String id;
  final String title;
  final String path;
  final int countClicks;
  final DateTime createdAt;
  final String destination;
  final DateTime updatedAt;
  final UserEntity user;

  const UrlEntity({
    required this.id,
    required this.title,
    required this.path,
    required this.countClicks,
    required this.createdAt,
    required this.destination,
    required this.updatedAt,
    required this.user,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    path,
    countClicks,
    createdAt,
    destination,
    updatedAt,
    user,
  ];
}

class UserEntity extends Equatable {
  final String id;
  final String name;

  const UserEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
