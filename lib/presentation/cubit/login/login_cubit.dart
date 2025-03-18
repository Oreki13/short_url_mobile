import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginCubitState> {
  LoginCubit() : super(const LoginCubitState());

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void setRememberMe(bool value) {
    emit(state.copyWith(rememberMe: value));
  }
}
