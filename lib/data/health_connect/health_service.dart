import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:collection';

class HealthService {
  final Health _health = Health();
  bool _isInitialized = false;
  final Map<String, Map<String, dynamic>> _sleepStatsCache = {};
  final Map<String, Map<String, dynamic>> _stepsStatsCache = {};
  final int _maxCacheSize = 30; // Guarda máximo 30 días
  final Queue<String> _cacheDateOrder = Queue<String>();
  final Queue<String> _stepsCacheDateOrder = Queue<String>();

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
      HealthDataType.STEPS,
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
      _cacheDateOrder.remove(key);
      _cacheDateOrder.add(key);
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

  Future<Map<String, dynamic>> getStepsStatistics(DateTime date) async {
    if (!_isInitialized) await initialize();
    final key = DateFormat('yyyy-MM-dd').format(date);

    if (_stepsStatsCache.containsKey(key)) {
      _stepsCacheDateOrder.remove(key);
      _stepsCacheDateOrder.add(key);
      return _stepsStatsCache[key]!;
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Map<String, dynamic> stats = {'totalSteps': 0};

    try {
      final steps = await _health.getTotalStepsInInterval(startOfDay, endOfDay);
      stats['totalSteps'] = steps ?? 0;
    } catch (e) {
      print("Error obteniendo datos de pasos para la fecha $date: $e");
      // No relanzar, simplemente devolver 0 pasos si hay error
    }

    _stepsStatsCache[key] = stats;
    _stepsCacheDateOrder.add(key);
    if (_stepsCacheDateOrder.length > _maxCacheSize) {
      final oldestKey = _stepsCacheDateOrder.removeFirst();
      _stepsStatsCache.remove(oldestKey);
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

  Future<List<Map<String, dynamic>>> getWeeklyStepsData(
    DateTime weekStart,
  ) async {
    if (!_isInitialized) await initialize();
    List<Map<String, dynamic>> weekData = [];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final stats = await getStepsStatistics(date);

      final dayStats = Map<String, dynamic>.from(stats);
      dayStats['date'] = date;
      dayStats['hasData'] = (stats['totalSteps'] as int? ?? 0) > 0;
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

  int _quantifySleepQuality(
    double totalMinutes,
    double deepPercentage,
    double remPercentage,
  ) {
    int score = 6; // Puntuación base

    // Evaluación de la duración del sueño
    if (totalMinutes < 360) {
      // Menos de 6 horas
      score -= 2;
    } else if (totalMinutes < 420) {
      // Entre 6 y 7 horas
      score -= 1;
    } else if (totalMinutes <= 540) {
      // Entre 7 y 9 horas (ideal)
      score += 1;
    }
    // Si es > 540 min (9 horas), no se penaliza ni bonifica adicionalmente por simplicidad.

    // Evaluación del porcentaje de sueño profundo
    if (deepPercentage < 10) {
      score -= 2;
    } else if (deepPercentage < 13) {
      score -= 1;
    } else if (deepPercentage <= 23) {
      // 13-23% (ideal)
      score += 1;
    }
    // Si es > 23%, no se penaliza ni bonifica adicionalmente.

    // Evaluación del porcentaje de sueño REM
    if (remPercentage < 15) {
      score -= 2;
    } else if (remPercentage < 20) {
      score -= 1;
    } else if (remPercentage <= 25) {
      // 20-25% (ideal)
      score += 1;
    }
    // Si es > 25%, no se penaliza ni bonifica adicionalmente.

    // Ajustar la puntuación al rango 0-9 (aprox.) y luego mapear a 1-10.
    // La 'score' calculada basada en los criterios anteriores varía aproximadamente de 0 (6-2-2-2) a 9 (6+1+1+1).
    // Sumamos 1 para cambiar este rango a 1-10.
    return (score + 1).clamp(
      1,
      10,
    ); // Asegura que la puntuación final esté entre 1 y 10.
  }

  // Datos agregados para el modelo, para el promedio de los últimos 30 días.
  Future<Map<String, dynamic>> getAggregatedHealthDataForModel({
    int daysWindow = 30,
  }) async {
    await ensureInitialized();

    // --- INICIO: BLOQUE DE PRUEBA ---
    /*
    return {
      'avg_sleep_duration_hours': 5.0,
      'sleep_quality_quantified': 2,
      'avg_heart_rate_bpm': 100,
      'avg_daily_steps': 2000,
    };
    // --- FIN: BLOQUE DE PRUEBA ---
    */

    double totalSleepMinutesSum = 0;
    double deepSleepMinutesSum = 0;
    double lightSleepMinutesSum = 0;
    double remSleepMinutesSum = 0;
    int daysWithSleepData = 0;

    double heartRateAggregatedSum = 0; // Suma de los promedios diarios de HR
    int daysWithHeartRateData = 0;

    double totalStepsSum = 0;
    int daysWithStepsData = 0; // Días para los que se procesaron datos de pasos

    final today = DateTime.now();

    for (int i = 0; i < daysWindow; i++) {
      // Iterar desde hoy hacia atrás
      final date = DateTime(today.year, today.month, today.day - i);

      // Datos de Sueño
      try {
        final sleepStats = await getSleepStatistics(date);
        // Solo sumar y contar si hay minutos de sueño registrados (mayores que 0)
        if (sleepStats['totalSleepMinutes'] != null &&
            (sleepStats['totalSleepMinutes'] as int) > 0) {
          totalSleepMinutesSum +=
              (sleepStats['totalSleepMinutes'] as int).toDouble();
          deepSleepMinutesSum +=
              (sleepStats['deepSleepMinutes'] as int? ?? 0).toDouble();
          lightSleepMinutesSum +=
              (sleepStats['lightSleepMinutes'] as int? ?? 0).toDouble();
          remSleepMinutesSum +=
              (sleepStats['remSleepMinutes'] as int? ?? 0).toDouble();
          daysWithSleepData++;
        }
        // Si totalSleepMinutes es 0 o null, no se suma ni se cuenta el día para el promedio de sueño.
      } catch (e) {
        print("Error obteniendo datos de sueño para $date en agregación: $e");
        // Este día no contribuirá a los datos de sueño si hay error.
      }

      // Datos de Ritmo Cardíaco
      try {
        final heartRatePoints = await getHeartRateDataByDate(date);
        final numericHeartRatePoints =
            heartRatePoints
                .where(
                  (p) =>
                      p.type == HealthDataType.HEART_RATE &&
                      p.value is NumericHealthValue &&
                      (p.value as NumericHealthValue).numericValue.isFinite,
                )
                .toList();

        if (numericHeartRatePoints.isNotEmpty) {
          double dailyHrSum = 0;
          for (var point in numericHeartRatePoints) {
            dailyHrSum +=
                (point.value as NumericHealthValue).numericValue.toDouble();
          }
          heartRateAggregatedSum +=
              (dailyHrSum / numericHeartRatePoints.length);
          daysWithHeartRateData++; // Correctamente cuenta solo días con datos de HR
        }
      } catch (e) {
        print(
          "Error obteniendo datos de ritmo cardíaco para $date en agregación: $e",
        );
        // Este día no contribuirá a los datos de HR si hay error.
      }

      // Datos de Pasos
      try {
        final stepsStats = await getStepsStatistics(date);
        // Solo sumar y contar si hay pasos registrados (mayores que 0)
        if (stepsStats['totalSteps'] != null &&
            (stepsStats['totalSteps'] as int) > 0) {
          totalStepsSum += (stepsStats['totalSteps'] as int).toDouble();
          daysWithStepsData++;
        }
        // Si totalSteps es 0 o null, no se suma ni se cuenta el día para el promedio de pasos.
      } catch (e) {
        print("Error obteniendo datos de pasos para $date en agregación: $e");
        // Este día no contribuirá a los datos de pasos si hay error.
      }
    }

    // Calcular Promedios de Sueño
    final double avgTotalSleepMinutes =
        daysWithSleepData > 0 ? totalSleepMinutesSum / daysWithSleepData : 0;
    final double avgDeepSleepMinutes =
        daysWithSleepData > 0 ? deepSleepMinutesSum / daysWithSleepData : 0;
    // final double avgLightSleepMinutes = daysWithSleepData > 0 ? lightSleepMinutesSum / daysWithSleepData : 0; // No usado directamente en cuantificación
    final double avgRemSleepMinutes =
        daysWithSleepData > 0 ? remSleepMinutesSum / daysWithSleepData : 0;

    final double avgSleepDurationHours = avgTotalSleepMinutes / 60.0;

    final double avgDeepSleepPercentage =
        avgTotalSleepMinutes > 0
            ? (avgDeepSleepMinutes / avgTotalSleepMinutes) * 100
            : 0;
    final double avgRemSleepPercentage =
        avgTotalSleepMinutes > 0
            ? (avgRemSleepMinutes / avgTotalSleepMinutes) * 100
            : 0;

    final int quantifiedSleepQuality = _quantifySleepQuality(
      avgTotalSleepMinutes,
      avgDeepSleepPercentage,
      avgRemSleepPercentage,
    );

    // Calcular Promedio de Ritmo Cardíaco
    final double avgHeartRate =
        daysWithHeartRateData > 0
            ? heartRateAggregatedSum / daysWithHeartRateData
            : 0;

    // Calcular Promedio de Pasos
    final double avgDailySteps =
        daysWithStepsData > 0 ? totalStepsSum / daysWithStepsData : 0;

    return {
      'avg_sleep_duration_hours': double.parse(
        avgSleepDurationHours.toStringAsFixed(1),
      ),
      'sleep_quality_quantified': quantifiedSleepQuality,
      'avg_heart_rate_bpm': avgHeartRate.round(),
      'avg_daily_steps': avgDailySteps.round(),
    };
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

class AggregatedHealthData {
  final double avgSleepDurationHours;
  final double sleepQualityQuantified;
  final double avgHeartRateBpm;
  final int avgDailySteps;

  AggregatedHealthData({
    required this.avgSleepDurationHours,
    required this.sleepQualityQuantified,
    required this.avgHeartRateBpm,
    required this.avgDailySteps,
  });
}
