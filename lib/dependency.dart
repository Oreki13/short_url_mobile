import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:short_url_mobile/core/cubit/connection_state.dart';
import 'package:short_url_mobile/core/services/dio_service.dart';
import 'package:short_url_mobile/core/cubit/theme_state.dart';
import 'package:short_url_mobile/core/services/network_info.dart';
import 'package:short_url_mobile/core/utility/logger_utility.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Logger
  final loggerUtil = LoggerUtil();
  loggerUtil.initialize();
  sl.registerLazySingleton(() => loggerUtil);

  // Shared Preferences
  final sharedPreference = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreference);
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());

  // Services
  sl.registerLazySingleton(() => DioService());
  sl<DioService>().initialize();

  // Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Cubit
  sl.registerFactory(() => ConnectionCubit(networkInfo: sl()));
  sl.registerLazySingleton(() => ThemeCubit(sl<SharedPreferences>()));
}
