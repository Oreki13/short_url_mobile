import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:short_url_mobile/core/constant/route_constant.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';
import 'package:short_url_mobile/presentation/bloc/login/login_bloc.dart';
import 'package:short_url_mobile/dependency.dart' as di;
import 'package:short_url_mobile/presentation/cubit/login/login_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: GlobalKey<ScaffoldMessengerState>(),
      child: _LoginView(
        emailController: emailController,
        passwordController: passwordController,
      ),
    );
  }
}

class _LoginView extends StatelessWidget {
  _LoginView({required this.emailController, required this.passwordController});

  // Controllers masih perlu dikelola di level widget karena mereka terkait dengan lifecycle
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<LoginBloc>()),
        BlocProvider(create: (_) => di.sl<LoginCubit>()),
      ],
      child: BlocListener<LoginBloc, LoginState>(
        listenWhen:
            (previous, current) =>
                previous.formStatus != current.formStatus &&
                (current.formStatus is SubmissionFailed ||
                    current.formStatus is SubmissionSuccess),
        listener: (context, state) {
          if (state.formStatus is SubmissionFailed) {
            final error = (state.formStatus as SubmissionFailed).exception;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(error),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          } else if (state.formStatus is SubmissionSuccess) {
            context.go(RouteConstants.root);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Logo
                    Icon(
                      Icons.link_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // App Name
                    Text(
                      'Short URL',
                      style: AppText.h1.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),

                    // Tagline
                    Text(
                      'Sign in to manage your short links',
                      style: AppText.bodyMedium.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.xl),

                    // Login Form
                    // Menggunakan BlocBuilder untuk memperbarui state
                    BlocBuilder<LoginBloc, LoginState>(
                      builder: (context, loginState) {
                        return Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email Field
                              TextFormField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email or Username',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMd,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onChanged:
                                    (value) => context.read<LoginBloc>().add(
                                      LoginUsernameChanged(value),
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email or username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppDimensions.md),

                              // Password Field - menggunakan BlocBuilder untuk UI Cubit
                              BlocBuilder<LoginCubit, LoginCubitState>(
                                builder: (context, uiState) {
                                  return TextFormField(
                                    controller: passwordController,
                                    obscureText: !uiState.isPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          uiState.isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          context
                                              .read<LoginCubit>()
                                              .togglePasswordVisibility();
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMd,
                                        ),
                                      ),
                                    ),
                                    onChanged:
                                        (value) => context
                                            .read<LoginBloc>()
                                            .add(LoginPasswordChanged(value)),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: AppDimensions.sm),

                              // Remember Me and Forgot Password Row
                              BlocBuilder<LoginCubit, LoginCubitState>(
                                builder: (context, uiState) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Remember Me Checkbox
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: uiState.rememberMe,
                                            onChanged: (value) {
                                              context
                                                  .read<LoginCubit>()
                                                  .setRememberMe(
                                                    value ?? false,
                                                  );
                                            },
                                          ),
                                          Text(
                                            'Remember me',
                                            style: AppText.bodySmall,
                                          ),
                                        ],
                                      ),

                                      // Forgot Password Button
                                      TextButton(
                                        onPressed: () {
                                          // Navigate to forgot password page
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: AppText.bodySmall.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: AppDimensions.lg),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: AppDimensions.buttonHeight,
                                child: ElevatedButton(
                                  onPressed:
                                      loginState.formStatus is FormSubmitting
                                          ? null
                                          : () => _submitForm(context),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusMd,
                                      ),
                                    ),
                                  ),
                                  child:
                                      loginState.formStatus is FormSubmitting
                                          ? const CircularProgressIndicator()
                                          : Text(
                                            'Sign In',
                                            style: AppText.button,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.xl),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: AppText.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to registration page
                          },
                          child: Text(
                            'Register',
                            style: AppText.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Ambil nilai rememberMe dari UI Cubit
      final rememberMe = context.read<LoginCubit>().state.rememberMe;

      context.read<LoginBloc>().add(
        LoginSubmitted(
          username: emailController.text,
          password: passwordController.text,
          rememberMe: rememberMe,
        ),
      );
    }
  }
}
