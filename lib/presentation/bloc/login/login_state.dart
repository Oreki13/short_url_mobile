part of 'login_bloc.dart';

class LoginState extends Equatable {
  final String username;
  final String password;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final FormSubmissionStatus formStatus;
  final String? errorMessage;

  const LoginState({
    this.username = '',
    this.password = '',
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.formStatus = const InitialFormStatus(),
    this.errorMessage,
  });

  LoginState copyWith({
    String? username,
    String? password,
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    FormSubmissionStatus? formStatus,
    String? errorMessage,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    username,
    password,
    accessToken,
    refreshToken,
    expiresIn,
    formStatus,
    errorMessage,
  ];
}

// Form submission status to track the form state
abstract class FormSubmissionStatus {
  const FormSubmissionStatus();
}

class InitialFormStatus extends FormSubmissionStatus {
  const InitialFormStatus();
}

class FormSubmitting extends FormSubmissionStatus {}

class SubmissionSuccess extends FormSubmissionStatus {}

class SubmissionFailed extends FormSubmissionStatus {
  final String exception;
  final FailureType? failureType;

  SubmissionFailed(this.exception, {this.failureType});

  List<Object?> get props => [exception, failureType];
}

enum FailureType { auth, network, server, cache, unexpected }
