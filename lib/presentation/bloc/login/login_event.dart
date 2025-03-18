part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginUsernameChanged extends LoginEvent {
  final String username;

  const LoginUsernameChanged(this.username);

  @override
  List<Object> get props => [username];
}

class LoginPasswordChanged extends LoginEvent {
  final String password;

  const LoginPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class LoginSubmitted extends LoginEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const LoginSubmitted({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object> get props => [username, password, rememberMe];
}

// Tambahkan di login_event.dart
class LoginResetError extends LoginEvent {
  const LoginResetError();
}
