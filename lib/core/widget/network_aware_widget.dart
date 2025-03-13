import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:short_url_mobile/core/cubit/connection_state.dart';

class NetworkAwareWidget extends StatelessWidget {
  final Widget onlineWidget;
  final Widget offlineWidget;

  const NetworkAwareWidget({
    super.key,
    required this.onlineWidget,
    required this.offlineWidget,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, state) {
        return state.status == ConnectionStatus.connected
            ? onlineWidget
            : offlineWidget;
      },
    );
  }
}
