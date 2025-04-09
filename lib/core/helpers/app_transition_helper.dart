import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppTransitionPage extends CustomTransitionPage {
  AppTransitionPage({required LocalKey super.key, required super.child})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Gunakan salah satu transisi berikut:

          // 1. Fade transition
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );

          // 2. Slide transition - horizontal
          // return SlideTransition(
          //   position: Tween<Offset>(
          //     begin: const Offset(0, 0.25),
          //     end: Offset.zero,
          //   ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
          //   child: FadeTransition(
          //     opacity: animation,
          //     child: child,
          //   ),
          // );

          // 3. Scale and fade transition
          // final curvedAnimation = CurvedAnimation(
          //   parent: animation,
          //   curve: Curves.easeInOut,
          // );
          //
          // return FadeTransition(
          //   opacity: curvedAnimation,
          //   child: ScaleTransition(
          //     scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
          //     child: child,
          //   ),
          // );
        },
      );
}
