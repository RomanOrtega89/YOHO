import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  Future<void> initialize() async {
    // Configura el plugin de salud
    await _health.configure();
  }

  Future<bool> requestPermissions() async {
    // Definir tipos de datos que quieres leer: sueño y ritmo cardíaco
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

    // Solicitar autorización para leer estos datos
    return await _health.requestAuthorization(types);
  }

  // Obtener datos de ritmo cardíaco
  Future<List<HealthDataPoint>> getHeartRateData() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7)); // Últimos 7 días

    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
    ];

    try {
      return await _health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: now,
      );
    } catch (e) {
      print("Error obteniendo datos de ritmo cardíaco: $e");
      return [];
    }
  }

  // Obtener datos de sueño
  Future<List<HealthDataPoint>> getSleepData() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30)); // Último mes

    final types = [
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
    ];

    try {
      return await _health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: now,
      );
    } catch (e) {
      print("Error obteniendo datos de sueño: $e");
      return [];
    }
  }

  // Verificar si hay acceso a los datos históricos
  Future<bool> checkAndRequestHistoricalAccess() async {
    bool isAvailable = await _health.isHealthDataInBackgroundAvailable();
    if (!isAvailable) return false;

    bool isAuthorized = await _health.isHealthDataInBackgroundAuthorized();
    if (!isAuthorized) {
      return await _health.requestHealthDataInBackgroundAuthorization();
    }
    return true;
  }
}
