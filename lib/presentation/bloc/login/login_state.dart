part of 'login_bloc.dart';

class LoginState extends Equatable {
  final String username;
  final String password;
  final String? token;
  final FormSubmissionStatus formStatus;
  final String? errorMessage;

  const LoginState({
    this.username = '',
    this.password = '',
    this.token,
    this.formStatus = const InitialFormStatus(),
    this.errorMessage,
  });

  LoginState copyWith({
    String? username,
    String? password,
    String? token,
    FormSubmissionStatus? formStatus,
    String? errorMessage,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      token: token ?? this.token,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    username,
    password,
    token,
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
