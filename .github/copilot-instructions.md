# Copilot Instructions - Aplikasi Short Link Mobile

## Deskripsi Aplikasi

Aplikasi short link mobile menggunakan Flutter untuk mempersingkat dan mengelola URL. Pengguna dapat melakukan CRUD (Create, Read, Update, Delete) operasi pada URL yang akan dipersingkat.

## Arsitektur dan Struktur Proyek

### Clean Architecture

Proyek ini menggunakan Clean Architecture dengan 3 layer utama:

1. **Presentation Layer**:

   - UI Components
   - Blocs/Cubits (State Management)
   - Pages/Screens

2. **Domain Layer**:

   - Entities
   - Use Cases
   - Repository Interfaces

3. **Data Layer**:
   - Repository Implementations
   - Data Sources (Remote & Local)
   - Models

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── cookie_manager.dart
│   │   └── network_info.dart
│   ├── utils/
│   └── extensions/
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── local_storage_service.dart
│   │   │   └── cache_manager.dart
│   │   └── remote/
│   │       └── api_service.dart
│   ├── models/
│   │   ├── short_link_model.dart
│   │   └── user_model.dart
│   └── repositories/
│       ├── short_link_repository_impl.dart
│       └── auth_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── short_link.dart
│   │   └── user.dart
│   ├── repositories/
│   │   ├── short_link_repository.dart
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── short_links/
│       │   ├── create_short_link.dart
│       │   ├── get_short_links.dart
│       │   ├── update_short_link.dart
│       │   └── delete_short_link.dart
│       └── auth/
│           ├── login_user.dart
│           └── logout_user.dart
└── presentation/
    ├── blocs/
    │   ├── auth/
    │   │   ├── auth_bloc.dart
    │   │   ├── auth_event.dart
    │   │   └── auth_state.dart
    │   └── short_link/
    │       ├── short_link_bloc.dart
    │       ├── short_link_event.dart
    │       └── short_link_state.dart
    ├── cubits/
    │   ├── theme/
    │   │   ├── theme_cubit.dart
    │   │   └── theme_state.dart
    │   └── connectivity/
    │       ├── connectivity_cubit.dart
    │       └── connectivity_state.dart
    ├── pages/
    │   ├── auth/
    │   │   ├── login_page.dart
    │   │   └── splash_page.dart
    │   └── short_link/
    │       ├── short_link_list_page.dart
    │       ├── short_link_detail_page.dart
    │       └── short_link_form_page.dart
    └── widgets/
        ├── common/
        └── short_link/
```

## State Management dengan BLoC dan Cubit

### Prinsip Utama:

- Semua variabel yang menyebabkan perubahan UI disimpan di Cubit atau Bloc
- Gunakan Bloc untuk alur logika yang kompleks dan event-driven
- Gunakan Cubit untuk state management yang lebih sederhana

### Contoh Implementasi Bloc untuk ShortLink:

```dart
// short_link_event.dart
abstract class ShortLinkEvent {}

class GetAllShortLinksEvent extends ShortLinkEvent {}
class CreateShortLinkEvent extends ShortLinkEvent {
  final String originalUrl;
  final String alias;

  CreateShortLinkEvent({required this.originalUrl, this.alias = ''});
}
class UpdateShortLinkEvent extends ShortLinkEvent {
  final String id;
  final String originalUrl;
  final String alias;

  UpdateShortLinkEvent({required this.id, required this.originalUrl, required this.alias});
}
class DeleteShortLinkEvent extends ShortLinkEvent {
  final String id;

  DeleteShortLinkEvent({required this.id});
}

// short_link_state.dart
abstract class ShortLinkState {}

class ShortLinkInitial extends ShortLinkState {}
class ShortLinkLoading extends ShortLinkState {}
class ShortLinkLoaded extends ShortLinkState {
  final List<ShortLink> links;

  ShortLinkLoaded({required this.links});
}
class ShortLinkError extends ShortLinkState {
  final String message;

  ShortLinkError({required this.message});
}

// short_link_bloc.dart
class ShortLinkBloc extends Bloc<ShortLinkEvent, ShortLinkState> {
  final GetShortLinks getShortLinks;
  final CreateShortLink createShortLink;
  final UpdateShortLink updateShortLink;
  final DeleteShortLink deleteShortLink;

  ShortLinkBloc({
    required this.getShortLinks,
    required this.createShortLink,
    required this.updateShortLink,
    required this.deleteShortLink
  }) : super(ShortLinkInitial()) {
    on<GetAllShortLinksEvent>(_onGetAllShortLinks);
    on<CreateShortLinkEvent>(_onCreateShortLink);
    on<UpdateShortLinkEvent>(_onUpdateShortLink);
    on<DeleteShortLinkEvent>(_onDeleteShortLink);
  }

  void _onGetAllShortLinks(GetAllShortLinksEvent event, Emitter<ShortLinkState> emit) async {
    emit(ShortLinkLoading());
    final result = await getShortLinks();
    result.fold(
      (failure) => emit(ShortLinkError(message: failure.message)),
      (links) => emit(ShortLinkLoaded(links: links))
    );
  }

  // Implementasi method lainnya...
}
```

### Contoh Implementasi Cubit untuk Auth:

```dart
// auth_state.dart
class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final User? user;
  final bool rememberMe;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.rememberMe = false
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    User? user,
    bool? rememberMe
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
      rememberMe: rememberMe ?? this.rememberMe
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, isLoading, errorMessage, user, rememberMe];
}

// auth_cubit.dart
class AuthCubit extends Cubit<AuthState> {
  final LoginUser loginUser;
  final LogoutUser logoutUser;
  final LocalStorageService localStorageService;

  AuthCubit({
    required this.loginUser,
    required this.logoutUser,
    required this.localStorageService
  }) : super(const AuthState());

  void login(String email, String password, bool rememberMe) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final params = LoginParams(email: email, password: password, rememberMe: rememberMe);
    final result = await loginUser(params);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        isAuthenticated: false
      )),
      (user) {
        if (rememberMe) {
          localStorageService.saveUser(user);
        }
        emit(state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          rememberMe: rememberMe,
          errorMessage: null
        ));
      }
    );
  }

  void checkAuthStatus() async {
    final savedUser = await localStorageService.getUser();
    if (savedUser != null) {
      emit(state.copyWith(
        isAuthenticated: true,
        user: savedUser,
        rememberMe: true
      ));
    }
  }

  // Implementasi method lainnya...
}
```

## Network Management

### Dio dengan Cookie Management

#### Setup Dio Client:

```dart
// dio_client.dart
class DioClient {
  final Dio _dio;
  final CookieManager _cookieManager;
  final String baseUrl;

  DioClient({required this.baseUrl}) :
    _dio = Dio(),
    _cookieManager = CookieManager(CookieJar()) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.contentType = 'application/json';

    // Add interceptors
    _dio.interceptors.add(_cookieManager);
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // Add error interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        // Handle common errors like 401, 404, etc.
        if (error.response?.statusCode == 401) {
          // Handle unauthorized error
        }
        return handler.next(error);
      }
    ));
  }

  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Implementasi method post, put, delete...
}
```

#### Cookie Management:

```dart
// cookie_manager.dart
class AppCookieManager {
  final CookieJar cookieJar;

  AppCookieManager({CookieJar? cookieJar}) :
    this.cookieJar = cookieJar ?? CookieJar();

  Future<void> saveCookies(String url, List<Cookie> cookies) async {
    await cookieJar.saveFromResponse(Uri.parse(url), cookies);
  }

  Future<List<Cookie>> loadCookies(String url) async {
    return await cookieJar.loadForRequest(Uri.parse(url));
  }

  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }
}
```

## Caching untuk Offline Access

### Implementasi dengan Hive:

```dart
// cache_manager.dart
class CacheManager {
  static const String shortLinksBox = 'shortLinksBox';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ShortLinkModelAdapter());
    await Hive.openBox<ShortLinkModel>(shortLinksBox);
  }

  Future<void> cacheShortLinks(List<ShortLinkModel> links) async {
    final box = Hive.box<ShortLinkModel>(shortLinksBox);
    await box.clear();
    await box.addAll(links);
  }

  List<ShortLinkModel> getCachedShortLinks() {
    final box = Hive.box<ShortLinkModel>(shortLinksBox);
    return box.values.toList();
  }

  Future<void> clearCache() async {
    final box = Hive.box<ShortLinkModel>(shortLinksBox);
    await box.clear();
  }
}
```

### Connectivity Management:

```dart
// connectivity_cubit.dart
enum ConnectivityStatus { online, offline }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;

  const ConnectivityState({required this.status});

  @override
  List<Object> get props => [status];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  ConnectivityCubit({Connectivity? connectivity}) :
    _connectivity = connectivity ?? Connectivity(),
    super(const ConnectivityState(status: ConnectivityStatus.online)) {
    _init();
  }

  void _init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        emit(const ConnectivityState(status: ConnectivityStatus.offline));
      } else {
        emit(const ConnectivityState(status: ConnectivityStatus.online));
      }
    });
  }

  Future<void> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      emit(const ConnectivityState(status: ConnectivityStatus.offline));
    } else {
      emit(const ConnectivityState(status: ConnectivityStatus.online));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
```

## Security Implementation

### Secure Storage for Sensitive Data:

```dart
// secure_storage_service.dart
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage}) :
    _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Implementasi method lainnya untuk data sensitif...
}
```

### API Security:

```dart
// security_interceptor.dart
class SecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers['X-API-Key'] = Config.apiKey;
    options.headers['X-Request-ID'] = Uuid().v4();

    // Prevent sensitive data leakage in logs
    if (options.data is Map && (options.data as Map).containsKey('password')) {
      final logData = Map<String, dynamic>.from(options.data);
      logData['password'] = '***********';
      print('REQUEST DATA: $logData');
    }

    super.onRequest(options, handler);
  }
}
```

## Principles and Patterns Implementation

### SOLID Principles:

1. **Single Responsibility Principle (SRP)**

   - Setiap class memiliki satu tanggung jawab, seperti `ShortLinkRepository` hanya mengelola operasi CRUD untuk short links

2. **Open/Closed Principle (OCP)**

   - Class terbuka untuk ekstensi tapi tertutup untuk modifikasi
   - Gunakan abstract classes dan interfaces untuk implementasi baru tanpa mengubah kode yang ada

3. **Liskov Substitution Principle (LSP)**

   - Subclasses dapat menggantikan base classes tanpa mengubah fungsionalitas program
   - Contoh: `LocalShortLinkDataSource` dan `RemoteShortLinkDataSource` dapat dipertukarkan

4. **Interface Segregation Principle (ISP)**

   - Interface dibuat spesifik sesuai kebutuhan client
   - Contoh: `ShortLinkRepository` memiliki method yang spesifik untuk short link operations

5. **Dependency Inversion Principle (DIP)**
   - High-level modules tidak bergantung pada low-level modules, keduanya bergantung pada abstractions
   - Gunakan dependency injection untuk memasukkan dependencies

### DRY (Don't Repeat Yourself):

- Gunakan abstract classes, mixins, dan inheritance untuk menghindari duplikasi kode
- Buat reusable widgets dan utility functions

### KISS (Keep It Simple, Stupid):

- Pertahankan setiap class dan method sederhana dan fokus pada satu tugas
- Hindari over-engineering dan kompleksitas yang tidak perlu

## Rekomendasi Design Pattern

1. **Repository Pattern**

   - Memisahkan logika akses data dari business logic
   - Menyediakan abstraksi untuk operasi data

2. **Factory Method Pattern**

   - Untuk pembuatan instance yang fleksibel

3. **Observer Pattern**

   - Diimplementasikan melalui BLoC dan Cubit untuk reactive programming
   - Mengupdate UI secara real-time ketika state berubah

4. **Adapter Pattern**

   - Untuk mengkonversi data dari API ke format yang digunakan dalam aplikasi

5. **Strategy Pattern**

   - Untuk beralih antara berbagai implementasi, seperti online vs offline data fetching

6. **Singleton Pattern**

   - Untuk service yang hanya membutuhkan satu instance (seperti DioClient)

7. **Builder Pattern**

   - Untuk konstruksi objek kompleks step-by-step

8. **Dependency Injection**
   - Menggunakan package seperti get_it untuk memudahkan unit testing dan loose coupling

## Testing

### Unit Testing:

- Test setiap usecase, repository, dan service secara terisolasi
- Mock dependencies menggunakan mockito

### Widget Testing:

- Test widget dan interaksi UI

### Integration Testing:

- Test alur utama aplikasi end-to-end

## Packages Rekomendasi

1. **State Management**

   - flutter_bloc: Implementasi BLoC pattern
   - equatable: Perbandingan objek yang efisien

2. **Network**

   - dio: HTTP client
   - cookie_jar: Manajemen cookie
   - dio_cookie_manager: Integrasi cookie dengan Dio

3. **Storage**

   - hive: Database NoSQL cepat untuk caching
   - flutter_secure_storage: Penyimpanan aman untuk data sensitif
   - shared_preferences: Preferensi pengguna

4. **Utilities**

   - dartz: Functional programming dengan Either untuk error handling
   - get_it: Dependency injection
   - connectivity_plus: Monitor status koneksi
   - intl: Internationalization dan formatting

5. **Security**
   - crypto: Enkripsi data
   - uuid: Generate UUID unik
   - flutter_dotenv: Variabel environment

## Catatan Implementasi

- Prioritaskan UI/UX yang responsif bahkan dalam kondisi offline
- Implementasikan proper error handling di semua layer
- Gunakan Future dan Stream dengan benar untuk operasi asynchronous
- Pastikan UI tetap responsive selama operasi lama dengan loading indicators
- Implementasikan proper logging untuk debugging dan analytics

```

Dengan struktur dan implementasi di atas, aplikasi short link mobile akan memiliki:

1. Clean Architecture yang jelas dan terorganisir
2. State management yang efektif dengan BLoC dan Cubit
3. Offline capability dengan caching
4. Security best practices
5. Prinsip SOLID, DRY, dan KISS yang diikuti dengan konsisten

Semua kode telah dioptimalkan sesuai standar industri dan best practices untuk pengembangan aplikasi Flutter modern.
```
