import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/health_connect/health_connect.dart';
import 'package:health/health.dart';
import 'dart:math';

// Modelo para datos diarios de sueño
class DailySleepData {
  final DateTime date;
  final double totalHours;
  final double deepHours;
  final double lightHours;
  final double remHours;

  DailySleepData({
    required this.date,
    required this.totalHours,
    required this.deepHours,
    required this.lightHours,
    required this.remHours,
  });
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final HealthService _healthService = HealthService();
  bool _isLoading = true;
  String _error = '';

  // Datos de sueño procesados
  List<DailySleepData> _dailySleepData = [];

  // Selector de semana
  DateTime _selectedWeekStart = DateTime.now();
  int _selectedWeekIndex = 0;
  List<DateTime> _availableWeeks = [];

  // Colores consistentes
  static const Color sleepColor = Color(0xFF5499FF); // Azul claro (Ligero)
  static const Color deepSleepColor = Color(0xFF293A8B); // Azul oscuro
  static const Color remSleepColor = Color(0xFF76D1FF); // Azul muy claro/cian

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _getStartOfWeek(DateTime.now());
    _fetchAndProcessSleepData();
  }

  Future<void> _fetchAndProcessSleepData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      List<HealthDataPoint> sleepData = await _healthService.getSleepData();
      _processSleepData(sleepData);
      _generateAvailableWeeks();

      _selectedWeekIndex = _availableWeeks.indexWhere(
        (date) => _isSameDay(date, _selectedWeekStart),
      );

      if (_selectedWeekIndex < 0 && _availableWeeks.isNotEmpty) {
        _selectedWeekIndex = 0;
        _selectedWeekStart = _availableWeeks.first;
      }
    } catch (e) {
      _error = 'Error al obtener datos estadísticos: $e';
      print(_error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _processSleepData(List<HealthDataPoint> sleepData) {
    _dailySleepData = [];

    // Filtrar sesiones de sueño
    List<HealthDataPoint> sleepSessions =
        sleepData.where((p) => p.type == HealthDataType.SLEEP_SESSION).toList();

    if (sleepSessions.isEmpty) return;

    // Ordenar por fecha descendente
    sleepSessions.sort((a, b) => b.dateTo.compareTo(a.dateTo));

    // Procesar cada sesión
    for (var session in sleepSessions) {
      // Fecha de la sesión (usamos la fecha de fin)
      final sessionDate = DateTime(
        session.dateTo.year,
        session.dateTo.month,
        session.dateTo.day,
      );

      // Duración total en horas
      final totalHours =
          session.dateTo.difference(session.dateFrom).inMinutes / 60.0;

      if (totalHours <= 0) continue;

      // Por defecto, asignamos porcentajes aproximados a cada tipo de sueño
      double deepHours = totalHours * 0.3; // 30% sueño profundo
      double lightHours = totalHours * 0.5; // 50% sueño ligero
      double remHours = totalHours * 0.2; // 20% REM

      // Buscar datos de fases específicas si existen
      final sleepPhases =
          sleepData
              .where(
                (p) =>
                    p.type != HealthDataType.SLEEP_SESSION &&
                    p.dateFrom.isAfter(session.dateFrom) &&
                    p.dateTo.isBefore(session.dateTo),
              )
              .toList();

      if (sleepPhases.isNotEmpty) {
        Map<HealthDataType, double> phaseDurations = {};

        for (var phase in sleepPhases) {
          final duration =
              phase.dateTo.difference(phase.dateFrom).inMinutes / 60.0;
          phaseDurations[phase.type] =
              (phaseDurations[phase.type] ?? 0) + duration;
        }

        // Si tenemos datos específicos, los usamos
        if (phaseDurations.keys.isNotEmpty) {
          deepHours = phaseDurations[HealthDataType.SLEEP_DEEP] ?? deepHours;
          lightHours = phaseDurations[HealthDataType.SLEEP_LIGHT] ?? lightHours;
          remHours = phaseDurations[HealthDataType.SLEEP_REM] ?? remHours;
        }
      }

      // Añadir a los datos diarios
      _dailySleepData.add(
        DailySleepData(
          date: sessionDate,
          totalHours: totalHours,
          deepHours: deepHours,
          lightHours: lightHours,
          remHours: remHours,
        ),
      );
    }

    // Eliminar duplicados (manteniendo solo el más reciente por día)
    final Map<String, DailySleepData> uniqueData = {};
    for (var data in _dailySleepData) {
      final key = DateFormat('yyyy-MM-dd').format(data.date);
      uniqueData[key] = data;
    }

    _dailySleepData = uniqueData.values.toList();

    // Ordenar por fecha
    _dailySleepData.sort((a, b) => a.date.compareTo(b.date));
  }

  void _generateAvailableWeeks() {
    if (_dailySleepData.isEmpty) {
      _availableWeeks = [_getStartOfWeek(DateTime.now())];
      return;
    }

    // Crear un conjunto de semanas únicas desde los datos
    final Set<String> weekKeys = {};
    for (var data in _dailySleepData) {
      final weekStart = _getStartOfWeek(data.date);
      weekKeys.add(DateFormat('yyyy-MM-dd').format(weekStart));
    }

    // Convertir a lista de DateTime
    _availableWeeks =
        weekKeys.map((key) => DateFormat('yyyy-MM-dd').parse(key)).toList()
          ..sort(
            (a, b) => b.compareTo(a),
          ); // Ordenar descendente (más reciente primero)
  }

  void _selectPreviousWeek() {
    if (_selectedWeekIndex < _availableWeeks.length - 1) {
      setState(() {
        _selectedWeekIndex++;
        _selectedWeekStart = _availableWeeks[_selectedWeekIndex];
      });
    }
  }

  void _selectNextWeek() {
    if (_selectedWeekIndex > 0) {
      setState(() {
        _selectedWeekIndex--;
        _selectedWeekStart = _availableWeeks[_selectedWeekIndex];
      });
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Considera el lunes como inicio de semana
    int daysToSubtract = date.weekday - 1; // Lunes es 1, Domingo es 7
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Estadísticas de Salud'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _dailySleepData.isEmpty
              ? const Center(
                child: Text(
                  'No hay datos suficientes para estadísticas.',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeekSelector(),
                    const SizedBox(height: 16),
                    _buildChartCard(
                      title: 'Promedio Horas de Sueño (Semanal)',
                      icon: Icons.bedtime_outlined,
                      iconColor: Colors.purpleAccent,
                      child: _buildWeeklySleepChart(context),
                    ),
                    const SizedBox(height: 24),
                    _buildChartCard(
                      title: 'Estadísticas de Sueño (Mensual)',
                      icon: Icons.calendar_month,
                      iconColor: Colors.purpleAccent,
                      child: _buildMonthlySleepChart(context),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildWeekSelector() {
    final endOfWeek = _selectedWeekStart.add(const Duration(days: 6));

    final startFormatted = DateFormat('dd MMM').format(_selectedWeekStart);
    final endFormatted = DateFormat('dd MMM').format(endOfWeek);

    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white70,
                size: 20,
              ),
              onPressed:
                  _selectedWeekIndex < _availableWeeks.length - 1
                      ? _selectPreviousWeek
                      : null,
              color:
                  _selectedWeekIndex < _availableWeeks.length - 1
                      ? Colors.white
                      : Colors.grey,
            ),
            Text(
              'Semana: $startFormatted - $endFormatted',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: _selectedWeekIndex > 0 ? _selectNextWeek : null,
              color: _selectedWeekIndex > 0 ? Colors.white : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(height: 250, child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySleepChart(BuildContext context) {
    if (_dailySleepData.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: Colors.white)),
      );
    }

    // Generar mapa con datos por día para la semana seleccionada
    final Map<int, DailySleepData> dayDataMap = {};

    // Obtener fecha actual para no mostrar datos futuros
    final DateTime now = DateTime.now();

    // Obtener rango de fechas para la semana seleccionada
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = _selectedWeekStart.add(Duration(days: dayIndex));

      // No mostrar datos para fechas futuras
      if (date.isAfter(now)) continue;

      // Buscar datos para esta fecha específica
      for (var data in _dailySleepData) {
        if (_isSameDay(data.date, date) && data.totalHours > 2) {
          dayDataMap[dayIndex] = data;
          break;
        }
      }
    }

    if (dayDataMap.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos para la semana seleccionada',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Calcular el máximo valor para el eje Y
    final maxY = dayDataMap.values
        .map((data) => data.totalHours)
        .fold(0.0, max)
        .clamp(6.5, 10.0);

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.grey[800]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 5,
              getTitlesWidget:
                  (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${value.toStringAsFixed(1)}h',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > 6) {
                  return Container();
                }

                final date = _selectedWeekStart.add(Duration(days: index));
                String dayName = DateFormat('E').format(date);
                String dayNum = DateFormat('d').format(date);

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                      Text(
                        dayNum,
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[600]!, width: 1),
            left: BorderSide(color: Colors.grey[600]!, width: 1),
          ),
        ),
        barGroups: List.generate(7, (dayIndex) {
          // Si no hay datos para este día o es fecha futura, mostrar barra vacía
          final date = _selectedWeekStart.add(Duration(days: dayIndex));
          if (!dayDataMap.containsKey(dayIndex) || date.isAfter(now)) {
            return BarChartGroupData(
              x: dayIndex,
              barRods: [
                BarChartRodData(
                  toY: 0.1,
                  color: Colors.grey[700],
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }

          final data = dayDataMap[dayIndex]!;

          return BarChartGroupData(
            x: dayIndex,
            barRods: [
              BarChartRodData(
                toY: data.totalHours,
                width: 16,
                color: sleepColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dayIndex = group.x;
              if (!dayDataMap.containsKey(dayIndex)) {
                return null;
              }

              final data = dayDataMap[dayIndex]!;
              final date = _selectedWeekStart.add(Duration(days: dayIndex));
              final dateStr = DateFormat('E, d MMM').format(date);

              return BarTooltipItem(
                '$dateStr\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Total: ${data.totalHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySleepChart(BuildContext context) {
    if (_dailySleepData.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos mensuales',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Obtener los datos del último mes (30 días)
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    final monthlyData =
        _dailySleepData
            .where(
              (data) => data.date.isAfter(oneMonthAgo) && data.totalHours > 2,
            )
            .toList();

    if (monthlyData.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos para el último mes',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Calcular promedios mensuales
    double totalSleepHours = 0;
    double totalDeepHours = 0;
    double totalLightHours = 0;
    double totalRemHours = 0;

    for (var data in monthlyData) {
      totalSleepHours += data.totalHours;
      totalDeepHours += data.deepHours;
      totalLightHours += data.lightHours;
      totalRemHours += data.remHours;
    }

    final avgSleepHours = totalSleepHours / monthlyData.length;
    final avgDeepHours = totalDeepHours / monthlyData.length;
    final avgLightHours = totalLightHours / monthlyData.length;
    final avgRemHours = totalRemHours / monthlyData.length;

    // Calcular porcentajes
    final deepPercent = avgDeepHours / avgSleepHours;
    final lightPercent = avgLightHours / avgSleepHours;
    final remPercent = avgRemHours / avgSleepHours;

    return Column(
      children: [
        // Totales y promedio
        Text(
          '${avgSleepHours.toStringAsFixed(1)}h',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'Promedio mensual',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        // Gráfico simplificado
        Container(
          height: 120,
          child: Row(
            children: [
              // Información
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSleepInfoItem(
                      'Profundo',
                      avgDeepHours,
                      deepSleepColor,
                    ),
                    const SizedBox(height: 8),
                    _buildSleepInfoItem('Ligero', avgLightHours, sleepColor),
                    const SizedBox(height: 8),
                    _buildSleepInfoItem('REM', avgRemHours, remSleepColor),
                  ],
                ),
              ),

              // Gráfico
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 25,
                    sections: [
                      PieChartSectionData(
                        value: avgDeepHours,
                        color: deepSleepColor,
                        radius: 45,
                        title: '${(deepPercent * 100).toInt()}%',
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: avgLightHours,
                        color: sleepColor,
                        radius: 45,
                        title: '${(lightPercent * 100).toInt()}%',
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: avgRemHours,
                        color: remSleepColor,
                        radius: 45,
                        title: '${(remPercent * 100).toInt()}%',
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepInfoItem(String label, double hours, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${hours.toStringAsFixed(1)}h',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }
}
