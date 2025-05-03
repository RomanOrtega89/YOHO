import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:collection';

class HealthService {
  final Health _health = Health();
  bool _isInitialized = false;
  final Map<String, Map<String, dynamic>> _sleepStatsCache = {};
  final int _maxCacheSize = 30; // Guarda máximo 30 días
  final Queue<String> _cacheDateOrder = Queue<String>();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _health.configure();
      _isInitialized = true;
    } catch (e) {
      print("Error al inicializar el servicio de salud: $e");
      throw HealthServiceException('Error de inicialización', originalError: e);
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    // Solicitar permiso de actividad para datos de fitness
    await Permission.activityRecognition.request();

    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
    ];

    try {
      bool authorized = await _health.requestAuthorization(types);

      if (authorized) {
        await checkAndRequestHistoricalAccess();
      }

      return authorized;
    } catch (e) {
      print("Error al solicitar permisos: $e");
      rethrow;
    }
  }

  Future<List<HealthDataPoint>> getHeartRateData() async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));

    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
    ];

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: now,
      );

      // Eliminar duplicados para mejorar rendimiento
      return _health.removeDuplicates(data);
    } catch (e) {
      print("Error obteniendo datos de ritmo cardíaco: $e");
      throw HealthServiceException(
        'Error obteniendo datos de ritmo cardíaco',
        originalError: e,
      );
    }
  }

  Future<List<HealthDataPoint>> getSleepData() async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));

    final types = [
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
    ];

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: now,
      );

      // Eliminar duplicados para mejorar rendimiento
      return _health.removeDuplicates(data);
    } catch (e) {
      print("Error obteniendo datos de sueño: $e");
      rethrow;
    }
  }

  Future<bool> checkAndRequestHistoricalAccess() async {
    if (!_isInitialized) await initialize();

    try {
      // Verificar acceso a datos históricos
      bool isAuthorized = await _health.isHealthDataHistoryAuthorized();

      if (!isAuthorized) {
        return await _health.requestHealthDataHistoryAuthorization();
      }

      return true;
    } catch (e) {
      print("Error al solicitar acceso a datos históricos: $e");
      rethrow;
    }
  }

  Future<bool> isBackgroundReadAvailable() async {
    if (!_isInitialized) await initialize();

    try {
      return await _health.isHealthDataInBackgroundAvailable();
    } catch (e) {
      print("Error al verificar lectura en segundo plano: $e");
      rethrow;
    }
  }

  Future<bool> requestBackgroundAccess() async {
    if (!_isInitialized) await initialize();

    try {
      bool isAuthorized = await _health.isHealthDataInBackgroundAuthorized();

      if (!isAuthorized) {
        return await _health.requestHealthDataInBackgroundAuthorization();
      }

      return true;
    } catch (e) {
      print("Error al solicitar acceso en segundo plano: $e");
      rethrow;
    }
  }

  Future<List<HealthDataPoint>> getSleepDataByDate(DateTime date) async {
    if (!_isInitialized) await initialize();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final types = [
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
    ];

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      return _health.removeDuplicates(data);
    } catch (e) {
      print("Error obteniendo datos de sueño para la fecha $date: $e");
      rethrow;
    }
  }

  Future<List<HealthDataPoint>> getHeartRateDataByDate(DateTime date) async {
    if (!_isInitialized) await initialize();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
    ];

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      return _health.removeDuplicates(data);
    } catch (e) {
      print("Error obteniendo datos de ritmo cardíaco para la fecha $date: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSleepStatistics(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (_sleepStatsCache.containsKey(key)) {
      return _sleepStatsCache[key]!;
    }

    final sleepData = await getSleepDataByDate(date);

    // Valores por defecto
    Map<String, dynamic> stats = {
      'totalSleepMinutes': 0,
      'deepSleepMinutes': 0,
      'lightSleepMinutes': 0,
      'remSleepMinutes': 0,
      'awakeSleepMinutes': 0,
      'sleepSessions': 0,
    };

    // Filtrar sesiones de sueño
    List<HealthDataPoint> sleepSessions =
        sleepData.where((p) => p.type == HealthDataType.SLEEP_SESSION).toList();

    if (sleepSessions.isEmpty) return stats;

    // Contar sesiones
    stats['sleepSessions'] = sleepSessions.length;

    // Calcular tiempo total de sueño
    int totalMinutes = 0;
    for (var session in sleepSessions) {
      totalMinutes += session.dateTo.difference(session.dateFrom).inMinutes;
    }
    stats['totalSleepMinutes'] = totalMinutes;

    // Procesar datos por fase de sueño
    for (var point in sleepData) {
      final minutes = point.dateTo.difference(point.dateFrom).inMinutes;

      switch (point.type) {
        case HealthDataType.SLEEP_DEEP:
          stats['deepSleepMinutes'] =
              (stats['deepSleepMinutes'] as int) + minutes;
          break;
        case HealthDataType.SLEEP_LIGHT:
          stats['lightSleepMinutes'] =
              (stats['lightSleepMinutes'] as int) + minutes;
          break;
        case HealthDataType.SLEEP_REM:
          stats['remSleepMinutes'] =
              (stats['remSleepMinutes'] as int) + minutes;
          break;
        case HealthDataType.SLEEP_AWAKE:
          stats['awakeSleepMinutes'] =
              (stats['awakeSleepMinutes'] as int) + minutes;
          break;
        default:
          break;
      }
    }

    // Verificar consistencia de datos
    if (stats['deepSleepMinutes'] +
            stats['lightSleepMinutes'] +
            stats['remSleepMinutes'] >
        0) {
      // Siempre ajustar para asegurar coherencia
      double factor =
          stats['totalSleepMinutes'] /
          (stats['deepSleepMinutes'] +
              stats['lightSleepMinutes'] +
              stats['remSleepMinutes']);
      factor = factor.clamp(0.1, 10.0); // Límites más razonables

      if (factor != 1.0) {
        stats['deepSleepMinutes'] =
            (stats['deepSleepMinutes'] * factor).round();
        stats['lightSleepMinutes'] =
            (stats['lightSleepMinutes'] * factor).round();
        stats['remSleepMinutes'] = (stats['remSleepMinutes'] * factor).round();
      }
    }

    _sleepStatsCache[key] = stats;
    _cacheDateOrder.add(key);
    // Eliminar entradas antiguas si excede el límite
    if (_cacheDateOrder.length > _maxCacheSize) {
      final oldestKey = _cacheDateOrder.removeFirst();
      _sleepStatsCache.remove(oldestKey);
    }
    return stats;
  }

  Future<List<Map<String, dynamic>>> getWeeklySleepData(
    DateTime weekStart,
  ) async {
    List<Map<String, dynamic>> weekData = [];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final stats = await getSleepStatistics(date);

      // Siempre añadir datos para todos los días de la semana
      final dayStats = Map<String, dynamic>.from(stats);
      dayStats['date'] = date;
      dayStats['hasData'] = stats['totalSleepMinutes'] > 0;
      weekData.add(dayStats);
    }

    return weekData;
  }

  bool get isInitialized => _isInitialized;

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

// Crear una clase de error específica
class HealthServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  HealthServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'HealthServiceException: $message${code != null ? ' (code: $code)' : ''}';
}
