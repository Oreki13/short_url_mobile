import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:short_url_mobile/core/cubit/connection_state.dart';
import 'package:short_url_mobile/core/theme/app_theme.dart';
import 'package:short_url_mobile/core/cubit/theme_state.dart';
import 'package:short_url_mobile/core/widget/connection_overlay_widget.dart';
import 'package:short_url_mobile/presentation/pages/home/home_page.dart';
import 'package:short_url_mobile/dependency.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<ThemeCubit>()),
        BlocProvider(
          create: (context) => di.sl<ConnectionCubit>()..checkConnection(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Short URL',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode,
          home: const ConnectionOverlayWidget(child: HomePage()),
          builder: (context, child) {
            return ConnectionOverlayWidget(child: child!);
          },
        );
      },
    );
  }
}
