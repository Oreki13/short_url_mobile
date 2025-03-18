import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:short_url_mobile/core/cubit/connection_state.dart';
import 'package:short_url_mobile/core/theme/app_color.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';

class ConnectionOverlayWidget extends StatelessWidget {
  final Widget child;

  const ConnectionOverlayWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, state) {
        final shouldShowOverlay = state.status == ConnectionStatus.disconnected;
        return Stack(
          children: [
            child,
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: shouldShowOverlay ? 0 : -100,
              child: Material(
                elevation: 8,
                color: AppColors.error,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm,
                    ),
                    height: 50,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: AppColors.white,
                          size: AppDimensions.iconMd,
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Text(
                            'No internet connection',
                            style: AppText.bodyMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () =>
                                  context
                                      .read<ConnectionCubit>()
                                      .checkConnection(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.white,
                          ),
                          child: Text(
                            'RETRY',
                            style: AppText.bodyMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
