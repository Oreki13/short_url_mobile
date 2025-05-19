import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:short_url_mobile/core/network/network_info.dart';

// States
enum ConnectionStatus { initial, connected, disconnected }

class ConnectionState extends Equatable {
  final ConnectionStatus status;
  final bool isCheckingConnection;

  const ConnectionState({
    required this.status,
    this.isCheckingConnection = false,
  });

  // Factory constructors for convenience
  factory ConnectionState.initial() =>
      const ConnectionState(status: ConnectionStatus.initial);
  factory ConnectionState.connected() =>
      const ConnectionState(status: ConnectionStatus.connected);
  factory ConnectionState.disconnected() =>
      const ConnectionState(status: ConnectionStatus.disconnected);
  factory ConnectionState.checking() => const ConnectionState(
    status: ConnectionStatus.initial,
    isCheckingConnection: true,
  );

  @override
  List<Object> get props => [status, isCheckingConnection];
}

// Cubit
class ConnectionCubit extends Cubit<ConnectionState> {
  final NetworkInfo networkInfo;
  late StreamSubscription _connectionStreamSubscription;
  Timer? _periodicCheckTimer;
  Timer? _debounceTimer;
  Timer? _bufferTimer;

  bool _initialCheckCompleted = false;
  ConnectionStatus _lastStatus = ConnectionStatus.initial;
  ConnectionStatus _lastReportedStatus = ConnectionStatus.initial;

  ConnectionCubit({required this.networkInfo})
    : super(ConnectionState.initial()) {
    // Perform initial check immediately but assume connected initially
    // to avoid showing overlay immediately
    emit(ConnectionState.connected());
    checkConnection(isInitialCheck: true);
  }

  void monitorConnection() {
    _connectionStreamSubscription = networkInfo.connectionStream.listen((
      isConnected,
    ) {
      // Only emit if the initial check is completed
      if (_initialCheckCompleted) {
        _handleConnectionChange(isConnected);
      }
    });

    startPeriodicCheck();
  }

  void _handleConnectionChange(bool isConnected) {
    final newStatus =
        isConnected
            ? ConnectionStatus.connected
            : ConnectionStatus.disconnected;

    // Skip if same as last reported status
    if (_lastReportedStatus == newStatus &&
        _lastReportedStatus != ConnectionStatus.initial) {
      return;
    }

    // Cancel previous debounce if any
    _debounceTimer?.cancel();

    // For disconnected state, debounce to avoid flickers
    if (newStatus == ConnectionStatus.disconnected) {
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        // Verify again before showing disconnected
        checkConnection();
      });
    } else {
      // For connected state, update immediately
      _lastReportedStatus = newStatus;
      emit(ConnectionState(status: newStatus));
    }
  }

  void startPeriodicCheck() {
    // Check connection every 15 seconds
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => checkConnection(),
    );
  }

  void _emitWithBuffer(ConnectionState newState) {
    // If we're transitioning from initial to disconnected, add buffer time
    if (_lastStatus == ConnectionStatus.initial &&
        newState.status == ConnectionStatus.disconnected) {
      // Cancel previous timer if any
      _bufferTimer?.cancel();

      // Wait 1 second to confirm disconnection before showing overlay
      _bufferTimer = Timer(const Duration(milliseconds: 1000), () {
        // Verify if we're still disconnected
        checkConnection();
      });
      return;
    }

    // In all other cases, emit immediately
    _lastStatus = newState.status;
    _lastReportedStatus = newState.status;
    emit(newState);
  }

  Future<void> checkConnection({bool isInitialCheck = false}) async {
    if (isInitialCheck) {
      // Don't change visual state during initial check
    }

    try {
      final isConnected = await networkInfo.isConnected;
      final status =
          isConnected
              ? ConnectionStatus.connected
              : ConnectionStatus.disconnected;

      final newState = ConnectionState(status: status);

      // Use buffer emission for smoother transitions
      _emitWithBuffer(newState);

      if (isInitialCheck && !_initialCheckCompleted) {
        _initialCheckCompleted = true;
        monitorConnection();
      }
    } catch (e) {
      // In case of error checking connection, assume connected
      _emitWithBuffer(ConnectionState.connected());
      if (isInitialCheck && !_initialCheckCompleted) {
        _initialCheckCompleted = true;
        monitorConnection();
      }
    }
  }

  @override
  Future<void> close() {
    _connectionStreamSubscription.cancel();
    _periodicCheckTimer?.cancel();
    _debounceTimer?.cancel();
    _bufferTimer?.cancel();
    return super.close();
  }
}
