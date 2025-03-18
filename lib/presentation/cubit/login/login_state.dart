part of 'login_cubit.dart';

class LoginCubitState extends Equatable {
  final bool isPasswordVisible;
  final bool rememberMe;

  const LoginCubitState({
    this.isPasswordVisible = false,
    this.rememberMe = false,
  });

  LoginCubitState copyWith({bool? isPasswordVisible, bool? rememberMe}) {
    return LoginCubitState(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  List<Object?> get props => [isPasswordVisible, rememberMe];
}

final class LoginInitial extends LoginCubitState {}
