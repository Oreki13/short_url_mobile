import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectionStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker) {
    connectionChecker.checkInterval = const Duration(seconds: 5);
    connectionChecker.addresses = [
      AddressCheckOption(uri: Uri.parse("https://www.google.com")),
      AddressCheckOption(uri: Uri.parse("https://httpbin.org/get")),
    ];
  }

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;

  @override
  Stream<bool> get connectionStream => connectionChecker.onStatusChange.map(
    (status) => status == InternetConnectionStatus.connected,
  );
}
