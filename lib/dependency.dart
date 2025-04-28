import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:short_url_mobile/core/cubit/connection_state.dart';
import 'package:short_url_mobile/core/helpers/secure_storage_helper.dart';
import 'package:short_url_mobile/core/services/dio_service.dart';
import 'package:short_url_mobile/core/cubit/theme_state.dart';
import 'package:short_url_mobile/core/services/network_info.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/data/datasources/local/secure_storage_data_local.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';
import 'package:short_url_mobile/data/datasources/remote/auth_data_api.dart';
import 'package:short_url_mobile/data/datasources/remote/short_data_api.dart';
import 'package:short_url_mobile/domain/repositories/auth_repository.dart';
import 'package:short_url_mobile/domain/repositories/url_repository.dart';
import 'package:short_url_mobile/domain/usecase/create_url_usecase.dart';
import 'package:short_url_mobile/domain/usecase/get_url_list_usecase.dart';
import 'package:short_url_mobile/presentation/bloc/login/login_bloc.dart';
import 'package:short_url_mobile/presentation/bloc/url_list/url_list_bloc.dart';
import 'package:short_url_mobile/presentation/cubit/login/login_cubit.dart';

final sl = GetIt.instance;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> init() async {
  // Logger
  final loggerUtil = LoggerUtil();
  loggerUtil.initialize();
  sl.registerLazySingleton(() => loggerUtil);

  // Shared Preferences
  final sharedPreference = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreference);
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());
  sl.registerLazySingleton<SecureStorageHelper>(() => SecureStorageHelper());

  // Services
  sl.registerLazySingleton(() => DioService());
  sl<DioService>().initialize();

  // Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Cubit
  sl.registerFactory(() => ConnectionCubit(networkInfo: sl()));
  sl.registerLazySingleton(() => ThemeCubit(sl<SharedPreferences>()));
  sl.registerFactory(() => LoginCubit());

  // Data sources
  sl.registerLazySingleton<AuthDataApi>(
    () => AuthDataApiImpl(dioService: sl(), logger: sl()),
  );
  sl.registerLazySingleton<UrlDataApi>(
    () => UrlDataApiImpl(dioService: sl(), logger: sl()),
  );

  // Local Data Sources - separated implementations
  sl.registerLazySingleton<SharedPreferenceDataLocal>(
    () => SharedPreferenceDataLocalImpl(sharedPreferences: sl(), logger: sl()),
  );
  sl.registerLazySingleton<SecureStorageDataLocal>(
    () => SecureStorageDataLocalImpl(secureStorage: sl(), logger: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(), // Using secure storage
      sharedPreferences: sl(), //
      dioService: sl(),
      logger: sl(),
    ),
  );
  sl.registerLazySingleton<UrlRepository>(
    () => UrlRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUrlListUseCase(sl()));
  sl.registerLazySingleton(() => CreateUrlUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => LoginBloc(authRepository: sl()));
  sl.registerFactory(() => UrlListBloc(getUrlList: sl(), createUrl: sl()));
}
