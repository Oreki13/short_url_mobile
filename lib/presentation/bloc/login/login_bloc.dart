import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/domain/repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc({required this.authRepository}) : super(const LoginState()) {
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginResetError>(_onResetError);
  }

  void _onUsernameChanged(
    LoginUsernameChanged event,
    Emitter<LoginState> emit,
  ) {
    if (state.formStatus is SubmissionFailed) {
      add(const LoginResetError());
    }
    emit(state.copyWith(username: event.username));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    if (state.formStatus is SubmissionFailed) {
      add(const LoginResetError());
    }
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Emit submitting state
    emit(state.copyWith(formStatus: FormSubmitting()));

    // Basic validation
    if (event.username.isEmpty || event.password.isEmpty) {
      emit(
        state.copyWith(
          formStatus: SubmissionFailed('Username and password cannot be empty'),
        ),
      );
      return;
    }

    // Call login API with Either response handling
    final result = await authRepository.login(
      username: event.username,
      password: event.password,
      rememberMe: event.rememberMe,
    );

    // Handle Either result with fold
    result.fold(
      // Left case - failure
      (failure) {
        String errorMessage;

        if (failure is AuthFailure) {
          errorMessage = failure.message ?? 'Authentication failed';
        } else if (failure is ServerFailure) {
          errorMessage =
              failure.message ?? 'Server error ${failure.statusCode}';
        } else if (failure is NetworkFailure) {
          errorMessage = failure.message ?? 'Network connection issue';
        } else {
          errorMessage = failure.message ?? 'An unexpected error occurred';
        }

        emit(state.copyWith(formStatus: SubmissionFailed(errorMessage)));
      },

      // Right case - success (now returns LoginEntity)
      (loginEntity) {
        // Can now use loginEntity properties if needed
        emit(
          state.copyWith(
            formStatus: SubmissionSuccess(),
            // Store token or other info if needed
            token: loginEntity.token,
          ),
        );
      },
    );
  }

  void _onResetError(LoginResetError event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(formStatus: const InitialFormStatus(), errorMessage: null),
    );
  }
}
