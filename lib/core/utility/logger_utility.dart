import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerUtil {
  // Singleton instance
  static final LoggerUtil _instance = LoggerUtil._internal();

  // Private constructor
  LoggerUtil._internal();

  // Factory constructor to return the singleton instance
  factory LoggerUtil() => _instance;

  // Logger instance
  late final Logger logger;

  // Initialize the logger
  void initialize() {
    logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        dateTimeFormat: (time) => DateTimeFormat.onlyTimeAndSinceStart(time),
      ),
      level: kDebugMode ? Level.debug : Level.info,
      filter: ProductionFilter(),
    );

    // Log initialization
    if (kDebugMode) {
      logger.i('Logger initialized with debug level');
    }
  }

  // Get a custom logger with a specific tag
  Logger getTaggedLogger(String tag) {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: (time) => DateTimeFormat.onlyTimeAndSinceStart(time),
      ),
      level: kDebugMode ? Level.debug : Level.info,
      filter: TagFilter(tag),
    );
  }

  // Log levels
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.f(message, error: error, stackTrace: stackTrace);
  }
}

// A custom filter for filtering logs by tag
class TagFilter extends LogFilter {
  final String tag;

  TagFilter(this.tag);

  @override
  bool shouldLog(LogEvent event) {
    // Only log in debug mode
    if (!kDebugMode) return false;

    // Log everything
    return true;
  }
}

// Production filter to limit logs in production
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only log warnings, errors, and wtf
    if (!kDebugMode) {
      return event.level.index >= Level.warning.index;
    }

    // In debug mode, log everything
    return true;
  }
}
