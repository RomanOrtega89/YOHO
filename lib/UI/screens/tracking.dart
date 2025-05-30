import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../data/health_connect/health_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final HealthService _healthService = HealthService();
  List<HealthDataPoint> _heartRateData = [];
  List<HealthDataPoint> _sleepData = [];
  bool _isLoading = true;
  String _error = '';

  // Variables para almacenar datos procesados de sueño
  Duration _totalSleep = Duration.zero;
  Duration _deepSleep = Duration.zero;
  Duration _lightSleep = Duration.zero;
  Duration _remSleep = Duration.zero;
  List<SleepSegment> _sleepSegments = [];

  // Variables para almacenar datos procesados de ritmo cardíaco
  int? _restingHr;
  int? _maxHr;
  int? _minHr;
  int? _avgHr;
  List<FlSpot> _hrSpots = [];

  // Variables para almacenar datos procesados de pasos
  int? _totalSteps;

  // En la clase _TrackingScreenState, añade estas variables
  DateTime _selectedSleepDate = DateTime.now().subtract(
    const Duration(days: 1),
  );
  TimeOfDay _selectedSleepStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _selectedSleepEndTime = const TimeOfDay(hour: 8, minute: 0);

  // Añadir esta variable para la fecha del ritmo cardíaco
  DateTime _selectedHeartRateDate = DateTime.now();

  // Añadir esta variable para la fecha de los pasos
  DateTime _selectedStepsDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await _healthService.initialize();
      bool permissionsGranted = await _healthService.requestPermissions();

      if (permissionsGranted) {
        // Obtener datos para la fecha seleccionada
        _heartRateData = await _healthService.getHeartRateDataByDate(
          _selectedHeartRateDate,
        );
        _sleepData = await _healthService.getSleepDataByDate(
          _selectedSleepDate,
        );

        _processSleepData();
        _processHeartRateData();
        _processStepsData();
      } else {
        _error = 'Permisos no concedidos.';
      }
    } catch (e) {
      _error = 'Error al obtener datos: $e';
      print(_error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _processSleepData() async {
    try {
      final stats = await _healthService.getSleepStatistics(_selectedSleepDate);

      // Convertir a formato esperado con protección
      _totalSleep = Duration(minutes: stats['totalSleepMinutes'] ?? 0);
      _deepSleep = Duration(minutes: stats['deepSleepMinutes'] ?? 0);
      _lightSleep = Duration(minutes: stats['lightSleepMinutes'] ?? 0);
      _remSleep = Duration(minutes: stats['remSleepMinutes'] ?? 0);

      // Obtener segmentos para visualización
      _sleepSegments = _createSleepSegmentsFromData(_sleepData);

      if (mounted) setState(() {});
    } catch (e) {
      print("Error al procesar datos de sueño: $e");
      _error = 'Error al procesar datos de sueño: $e';
      if (mounted) setState(() {});
    }
  }

  void _processHeartRateData() {
    List<HealthDataPoint> hrPoints =
        _heartRateData
            .where((p) => p.type == HealthDataType.HEART_RATE)
            .toList();

    hrPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    if (hrPoints.isEmpty) {
      _restingHr = null;
      _maxHr = null;
      _minHr = null;
      _avgHr = null;
      _hrSpots = [];
      return;
    }

    double sum = 0;
    _minHr = (hrPoints.first.value as NumericHealthValue).numericValue.toInt();
    _maxHr = (hrPoints.first.value as NumericHealthValue).numericValue.toInt();
    _hrSpots = [];

    for (var point in hrPoints) {
      final value = (point.value as NumericHealthValue).numericValue.toInt();
      sum += value;
      if (value < _minHr!) _minHr = value;
      if (value > _maxHr!) _maxHr = value;

      _hrSpots.add(
        FlSpot(
          point.dateFrom.millisecondsSinceEpoch.toDouble(),
          value.toDouble(),
        ),
      );
    }

    _avgHr = (sum / hrPoints.length).round();

    // Obtener Resting Heart Rate
    HealthDataPoint? restingHrPoint;
    try {
      restingHrPoint = _heartRateData.firstWhere(
        (p) => p.type == HealthDataType.RESTING_HEART_RATE,
      );
    } catch (e) {
      // No encontró datos de ritmo cardíaco en reposo
      restingHrPoint = null;
    }

    if (restingHrPoint != null) {
      _restingHr =
          (restingHrPoint.value as NumericHealthValue).numericValue.toInt();
    } else {
      _restingHr = null; // UI mostrará "No disponible"
    }
  }

  Future<void> _processStepsData() async {
    try {
      final stats = await _healthService.getStepsStatistics(_selectedStepsDate);
      if (mounted) {
        setState(() {
          _totalSteps = stats['totalSteps'] as int?;
        });
      }
    } catch (e) {
      print("Error al procesar datos de pasos: $e");
      if (mounted) {
        setState(() {
          _error = 'Error al procesar datos de pasos: $e';
          _totalSteps = null;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return "0 min";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    String result = "";
    if (hours > 0) {
      result += "${hours}h ";
    }
    result += "${minutes}min";
    return result.trim();
  }

  double _calculatePercentage(Duration part, Duration total) {
    if (total == Duration.zero || part == Duration.zero) return 0.0;
    return (part.inMinutes / total.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const Color deepSleepColor = Color(0xFF293A8B); // Azul oscuro
    const Color lightSleepColor = Color(0xFF5499FF); // Azul claro
    const Color remSleepColor = Color(0xFF76D1FF); // Azul muy claro/cian
    const Color awakeColor = Colors.grey; // Para posible estado despierto
    const Color hrColor = Color(0xFFF44336); // Rojo para HR
    const Color stepsColor = Colors.orange; // Naranja para Pasos

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking')),
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección Sueño
                    _buildSleepSection(
                      context,
                      deepSleepColor,
                      lightSleepColor,
                      remSleepColor,
                      awakeColor,
                    ),
                    const SizedBox(height: 32),
                    // Sección Ritmo Cardíaco
                    _buildHeartRateSection(context, hrColor),
                    const SizedBox(height: 32),
                    // Sección Pasos
                    _buildStepsSection(context, stepsColor),
                  ],
                ),
              ),
    );
  }

  Widget _buildSleepSection(
    BuildContext context,
    Color deepSleepColor,
    Color lightSleepColor,
    Color remSleepColor,
    Color awakeColor,
  ) {
    final totalMinutes = _totalSleep.inMinutes;
    final deepPercent = _calculatePercentage(_deepSleep, _totalSleep);
    final lightPercent = _calculatePercentage(_lightSleep, _totalSleep);
    final remPercent = _calculatePercentage(_remSleep, _totalSleep);

    // Formateo de la duración total
    String hours = (_totalSleep.inHours).toString();
    String minutes = (_totalSleep.inMinutes.remainder(
      60,
    )).toString().padLeft(2, '0');

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      color: Colors.purpleAccent,
                    ), // Icono de sueño
                    SizedBox(width: 8),
                    Text(
                      'Sueño',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Fuente: Redmi Watch 3 Active', // Esto debería ser dinámico
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${hours}h',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${minutes}min',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegend('Profundo', deepSleepColor),
                _buildLegend('Ligero', lightSleepColor),
                _buildLegend('REM', remSleepColor),
              ],
            ),
            const SizedBox(height: 20),
            // Gráfico de Sueño (Bar Chart)
            _buildSleepChart(
              context,
              deepSleepColor,
              lightSleepColor,
              remSleepColor,
              awakeColor,
            ),
            const SizedBox(height: 32),
            Text(
              'Etapas del sueño',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildSleepStageDetail(
              'Profundo',
              _deepSleep,
              deepPercent,
              deepSleepColor,
              "20%-40%",
            ),
            const SizedBox(height: 12),
            _buildSleepStageDetail(
              'Ligero',
              _lightSleep,
              lightPercent,
              lightSleepColor,
              "20%-60%",
              isHigh: lightPercent > 0.6,
            ),
            const SizedBox(height: 12),
            _buildSleepStageDetail(
              'REM',
              _remSleep,
              remPercent,
              remSleepColor,
              "10%-30%",
            ),
            // Añadir el selector de tiempo
            _buildSleepTimeSelector(context),
          ],
        ),
      ),
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

  Widget _buildSleepChart(
    BuildContext context,
    Color deepSleepColor,
    Color lightSleepColor,
    Color remSleepColor,
    Color awakeColor,
  ) {
    if (_sleepSegments.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de segmentos de sueño',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Calcular porcentajes para el gráfico de pastel
    final totalMinutes = _totalSleep.inMinutes;
    final deepMinutes = _deepSleep.inMinutes;
    final lightMinutes = _lightSleep.inMinutes;
    final remMinutes = _remSleep.inMinutes;

    // Si queremos mostrar también la hora de inicio/fin
    final startTime = _sleepSegments.first.startTime;
    final endTime = _sleepSegments.last.endTime;

    return Column(
      children: [
        // Gráfico de pastel
        SizedBox(
          height: 150,
          child: Row(
            children: [
              // Gráfico circular
              Expanded(
                flex: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(150, 150),
                      painter: SleepPieChartPainter(
                        deepSleepPercentage: deepMinutes / totalMinutes,
                        lightSleepPercentage: lightMinutes / totalMinutes,
                        remSleepPercentage: remMinutes / totalMinutes,
                        deepSleepColor: deepSleepColor,
                        lightSleepColor: lightSleepColor,
                        remSleepColor: remSleepColor,
                      ),
                    ),

                    Text(
                      '${(_totalSleep.inHours)}h\n${_totalSleep.inMinutes.remainder(60)}min',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Barras de información
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSleepSummaryLegend(
                      'Profundo',
                      deepSleepColor,
                      _formatDuration(_deepSleep),
                      '${(deepMinutes / totalMinutes * 100).toStringAsFixed(0)}%',
                    ),
                    SizedBox(height: 12),
                    _buildSleepSummaryLegend(
                      'Ligero',
                      lightSleepColor,
                      _formatDuration(_lightSleep),
                      '${(lightMinutes / totalMinutes * 100).toStringAsFixed(0)}%',
                    ),
                    SizedBox(height: 12),
                    _buildSleepSummaryLegend(
                      'REM',
                      remSleepColor,
                      _formatDuration(_remSleep),
                      '${(remMinutes / totalMinutes * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Línea de tiempo
        SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: Stack(
            children: [
              // Fondo de la línea de tiempo
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Visualización por hora
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalDuration = endTime.difference(startTime).inSeconds;
                  final width = constraints.maxWidth;

                  return Stack(
                    children: [
                      // Marcadores de hora
                      ...List.generate(8, (index) {
                        final position = width * (index / 7);
                        return Positioned(
                          left: position,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 1, color: Colors.grey[600]),
                        );
                      }),

                      // Segmentos de sueño
                      ...List.generate(_sleepSegments.length, (index) {
                        final segment = _sleepSegments[index];
                        final startOffset =
                            segment.startTime.difference(startTime).inSeconds;
                        final duration =
                            segment.endTime
                                .difference(segment.startTime)
                                .inSeconds;

                        final left = width * (startOffset / totalDuration);
                        final segmentWidth = width * (duration / totalDuration);

                        Color color;
                        switch (segment.stage) {
                          case SleepStage.deep:
                            color = deepSleepColor;
                            break;
                          case SleepStage.light:
                            color = lightSleepColor;
                            break;
                          case SleepStage.rem:
                            color = remSleepColor;
                            break;
                          case SleepStage.awake:
                            color = awakeColor;
                            break;
                          default:
                            color = Colors.transparent;
                        }

                        return Positioned(
                          left: left,
                          top: 0,
                          height: 50,
                          width: segmentWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // Etiquetas de tiempo
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('HH:mm').format(startTime),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Text(
                DateFormat('HH:mm').format(endTime),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepSummaryLegend(
    String title,
    Color color,
    String duration,
    String percentage,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              '$duration ($percentage)',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSleepStageDetail(
    String title,
    Duration duration,
    double percentage,
    Color color,
    String range, {
    bool isHigh = false,
  }) {
    // Calcular si el porcentaje está dentro del rango normal
    final rangeValues = range.replaceAll('%', '').split('-');
    double minRange = 0.0;
    double maxRange = 1.0;

    if (rangeValues.length == 2) {
      minRange = (double.tryParse(rangeValues[0]) ?? 0.0) / 100.0;
      maxRange = (double.tryParse(rangeValues[1]) ?? 100.0) / 100.0;
    }

    bool isWithinRange = percentage >= minRange && percentage <= maxRange;
    bool isLow = percentage < minRange && percentage > 0;

    // Icono para indicar el estado
    IconData statusIcon = Icons.check_circle;
    Color statusColor = Colors.green;
    String statusText = "";

    if (isHigh) {
      statusIcon = Icons.arrow_upward;
      statusColor = Colors.red;
      statusText = "Alto";
    } else if (isLow) {
      statusIcon = Icons.arrow_downward;
      statusColor = Colors.orange;
      statusText = "Bajo";
    } else if (isWithinRange) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      statusText = "Normal";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (statusText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          SizedBox(width: 2),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final rangeWidth = (maxRange - minRange) * constraints.maxWidth;
                final rangeLeft = minRange * constraints.maxWidth;

                return Stack(
                  children: [
                    Positioned(
                      left: rangeLeft,
                      top: 0,
                      bottom: 0,
                      width: rangeWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rango normal: $range',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTimeSelector(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24.0, bottom: 8.0),
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton.icon(
              icon: const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 18,
              ),
              label: Text(
                DateFormat('dd/MM/yyyy').format(_selectedSleepDate),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size(10, 36),
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedSleepDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Colors.purpleAccent,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() {
                    _selectedSleepDate = date;
                    _initializeAndFetchData();
                  });
                }
              },
            ),
          ),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.bedtime, color: Colors.white70, size: 18),
              label: Text(
                _selectedSleepStartTime.format(context),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size(10, 36),
              ),
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedSleepStartTime,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Colors.purpleAccent,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  setState(() {
                    _selectedSleepStartTime = time;
                    _initializeAndFetchData();
                  });
                }
              },
            ),
          ),
          Text('a', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(
                Icons.wb_sunny_outlined,
                color: Colors.white70,
                size: 18,
              ),
              label: Text(
                _selectedSleepEndTime.format(context),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size(10, 36),
              ),
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedSleepEndTime,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Colors.purpleAccent,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  setState(() {
                    _selectedSleepEndTime = time;
                    _initializeAndFetchData();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateSection(BuildContext context, Color hrColor) {
    final Color heartRateColor = Color(0xFFFF5252);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: heartRateColor),
                    const SizedBox(width: 8),
                    Text(
                      'Ritmo Cardíaco',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Añadir selector de fecha para ritmo cardíaco
                TextButton.icon(
                  icon: const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 18,
                  ),
                  label: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedHeartRateDate),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedHeartRateDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.redAccent,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedHeartRateDate = date;
                        // Cargar nuevos datos para la fecha seleccionada
                        _loadHeartRateDataForSelectedDate();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_hrSpots
                .isNotEmpty) // Mostrar última lectura y hora si hay datos
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_hrSpots.last.y.toInt()}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LPM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          _hrSpots.last.x.toInt(),
                        ),
                      ), // Mostrar hora de última lectura
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 16), // Espacio si no hay datos aún
            // Gráfico de Ritmo Cardíaco (Line Chart)
            _buildHeartRateChart(context, heartRateColor),
            const SizedBox(height: 24),
            const Text(
              'Resumen diario',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHrSummaryItem('Descansando', _restingHr, 'LPM'),
                _buildHrSummaryItem('Máximo', _maxHr, 'LPM'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHrSummaryItem('Mínimo', _minHr, 'LPM'),
                _buildHrSummaryItem('Media', _avgHr, 'LPM'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateChart(BuildContext context, Color hrColor) {
    if (_hrSpots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No hay datos de ritmo cardíaco para este día',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Definir el rango del día seleccionado (00:00 a 23:59)
    final startOfDay = DateTime(
      _selectedHeartRateDate.year,
      _selectedHeartRateDate.month,
      _selectedHeartRateDate.day,
    );
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    final minX = startOfDay.millisecondsSinceEpoch.toDouble();
    final maxX = endOfDay.millisecondsSinceEpoch.toDouble();

    // Establecer rango fijo para el eje Y (40-180)
    double minY = 40;
    double maxY = 120;

    // Reducir cantidad de puntos para mejor visualización si hay muchos
    final int maxDataPoints = 100;
    List<FlSpot> filteredSpots = _hrSpots;

    if (_hrSpots.length > maxDataPoints) {
      int step = (_hrSpots.length / maxDataPoints).ceil();
      filteredSpots = [];
      for (int i = 0; i < _hrSpots.length; i += step) {
        filteredSpots.add(_hrSpots[i]);
      }
      // Asegurar que se incluya el último punto
      if (filteredSpots.isEmpty || filteredSpots.last.x != _hrSpots.last.x) {
        filteredSpots.add(_hrSpots.last);
      }
    }

    final Color heartRateColor = Color(0xFFFF5252);

    // Calcular los timestamps para las marcas de tiempo específicas (00:00, 06:00, 12:00, 18:00, 00:00)
    final labels = [
      startOfDay,
      startOfDay.add(const Duration(hours: 6)),
      startOfDay.add(const Duration(hours: 12)),
      startOfDay.add(const Duration(hours: 18)),
      startOfDay.add(const Duration(hours: 24)),
    ];

    final labelTimestamps =
        labels.map((dt) => dt.millisecondsSinceEpoch.toDouble()).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 21600000, // 6 horas en milisegundos
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[800]!, strokeWidth: 0.5);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.grey[800]!, strokeWidth: 0.5);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 21600000, // 6 horas en milisegundos
                getTitlesWidget: (value, meta) {
                  // Convertir el valor a una hora del día
                  final dateTime = DateTime.fromMillisecondsSinceEpoch(
                    value.toInt(),
                  );

                  // Formatear la hora para las etiquetas específicas
                  if (dateTime.hour % 6 == 0 || dateTime.hour == 0) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 8.0,
                      child: Text(
                        DateFormat('HH:mm').format(dateTime),
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Mostrar solo los valores específicos en el eje Y
                  final allowedValues = [40, 60, 80, 100, 120, 140, 160, 180];
                  if (allowedValues.contains(value.toInt())) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      textAlign: TextAlign.left,
                    );
                  }
                  return const SizedBox.shrink();
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
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: filteredSpots,
              isCurved: true,
              color: heartRateColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: heartRateColor,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: heartRateColor.withOpacity(0.15),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                    flSpot.x.toInt(),
                  );
                  String time = DateFormat('HH:mm').format(dt);
                  return LineTooltipItem(
                    '${flSpot.y.toInt()} LPM\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: time,
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                    ],
                    textAlign: TextAlign.center,
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHrSummaryItem(String label, int? value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value?.toString() ?? '--', // Mostrar '--' si es null
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  List<SleepSegment> _createSleepSegmentsFromData(
    List<HealthDataPoint> sleepData,
  ) {
    // Si no hay datos, devolver lista vacía
    if (sleepData.isEmpty) {
      return [];
    }

    // Pre-filtrar y ordenar datos una sola vez
    final relevantData =
        sleepData
            .where(
              (p) =>
                  p.type == HealthDataType.SLEEP_DEEP ||
                  p.type == HealthDataType.SLEEP_LIGHT ||
                  p.type == HealthDataType.SLEEP_REM ||
                  p.type == HealthDataType.SLEEP_AWAKE,
            )
            .toList()
          ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    // Lista para almacenar segmentos procesados
    List<SleepSegment> segments = [];

    // Si no hay datos relevantes, devolver lista vacía
    if (relevantData.isEmpty) {
      return segments;
    }

    // Procesar cada punto de datos en fase de sueño
    for (var point in relevantData) {
      SleepStage stage = SleepStage.unknown;

      switch (point.type) {
        case HealthDataType.SLEEP_DEEP:
          stage = SleepStage.deep;
          break;
        case HealthDataType.SLEEP_LIGHT:
          stage = SleepStage.light;
          break;
        case HealthDataType.SLEEP_REM:
          stage = SleepStage.rem;
          break;
        case HealthDataType.SLEEP_AWAKE:
          stage = SleepStage.awake;
          break;
        default:
          continue;
      }

      // Añadir segmento solo si la duración es válida
      if (point.dateFrom.isBefore(point.dateTo)) {
        segments.add(SleepSegment(point.dateFrom, point.dateTo, stage));
      }
    }

    // Opcional: optimizar combinando segmentos adyacentes del mismo tipo
    if (segments.length > 1) {
      List<SleepSegment> optimizedSegments = [segments.first];

      for (int i = 1; i < segments.length; i++) {
        SleepSegment current = segments[i];
        SleepSegment previous = optimizedSegments.last;

        // Si son del mismo tipo y contiguos (o con pequeña diferencia), combinar
        if (current.stage == previous.stage &&
            current.startTime.difference(previous.endTime).inMinutes < 5) {
          // Reemplazar el último segmento con uno combinado
          optimizedSegments.removeLast();
          optimizedSegments.add(
            SleepSegment(previous.startTime, current.endTime, current.stage),
          );
        } else {
          optimizedSegments.add(current);
        }
      }

      return optimizedSegments;
    }

    return segments;
  }

  Future<void> _loadHeartRateDataForSelectedDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener datos para la fecha seleccionada
      _heartRateData = await _healthService.getHeartRateDataByDate(
        _selectedHeartRateDate,
      );

      // Procesar los datos obtenidos
      _processHeartRateData();
    } catch (e) {
      print("Error al cargar datos de ritmo cardíaco: $e");
      setState(() {
        _error = 'Error al cargar datos de ritmo cardíaco: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStepsSection(BuildContext context, Color stepsColor) {
    final NumberFormat numberFormatter = NumberFormat.decimalPattern('es_ES');

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_walk, color: stepsColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Pasos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 18,
                  ),
                  label: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedStepsDate),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedStepsDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: stepsColor,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedStepsDate = date;
                        _loadStepsDataForSelectedDate();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    _totalSteps != null
                        ? numberFormatter.format(_totalSteps)
                        : '--',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'pasos hoy',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Aquí podrías añadir un gráfico de barras simple para pasos si lo deseas en el futuro
            // Por ahora, solo mostramos el total.
            // Ejemplo:
            if (_totalSteps != null && _totalSteps! > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: LinearProgressIndicator(
                  value: (_totalSteps! / 10000).clamp(
                    0.0,
                    1.0,
                  ), // Suponiendo un objetivo de 10000 pasos
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(stepsColor),
                  minHeight: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStepsDataForSelectedDate() async {
    setState(() {
      _isLoading =
          true; // Puedes usar un indicador de carga específico si prefieres
    });

    try {
      await _processStepsData(); // Reutiliza el método de procesamiento
    } catch (e) {
      print("Error al cargar datos de pasos: $e");
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos de pasos: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Enum y Clase auxiliar para el gráfico de sueño
enum SleepStage { deep, light, rem, awake, unknown }

class SleepSegment {
  final DateTime startTime;
  final DateTime endTime;
  final SleepStage stage;

  SleepSegment(this.startTime, this.endTime, this.stage);
}

// Clase para dibujar el gráfico de pastel
class SleepPieChartPainter extends CustomPainter {
  final double deepSleepPercentage;
  final double lightSleepPercentage;
  final double remSleepPercentage;
  final Color deepSleepColor;
  final Color lightSleepColor;
  final Color remSleepColor;

  SleepPieChartPainter({
    required this.deepSleepPercentage,
    required this.lightSleepPercentage,
    required this.remSleepPercentage,
    required this.deepSleepColor,
    required this.lightSleepColor,
    required this.remSleepColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2,
    );

    // Calcular ángulos para cada sección
    final double deepSleepAngle = deepSleepPercentage * 360;
    final double lightSleepAngle = lightSleepPercentage * 360;
    final double remSleepAngle = remSleepPercentage * 360;
    double startAngle = -90; // Comenzar desde arriba (90 grados)

    // Dibujar segmentos
    final paint = Paint()..style = PaintingStyle.fill;

    // Sueño profundo
    paint.color = deepSleepColor;
    canvas.drawArc(
      rect,
      _degreesToRadians(startAngle),
      _degreesToRadians(deepSleepAngle),
      true,
      paint,
    );
    startAngle += deepSleepAngle;

    // Sueño ligero
    paint.color = lightSleepColor;
    canvas.drawArc(
      rect,
      _degreesToRadians(startAngle),
      _degreesToRadians(lightSleepAngle),
      true,
      paint,
    );
    startAngle += lightSleepAngle;

    // Sueño REM
    paint.color = remSleepColor;
    canvas.drawArc(
      rect,
      _degreesToRadians(startAngle),
      _degreesToRadians(remSleepAngle),
      true,
      paint,
    );

    // Dibujar un círculo interno para crear efecto de dona (opcional)
    paint.color = Colors.grey[900]!;
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  @override
  bool shouldRepaint(SleepPieChartPainter oldDelegate) =>
      oldDelegate.deepSleepPercentage != deepSleepPercentage ||
      oldDelegate.lightSleepPercentage != lightSleepPercentage ||
      oldDelegate.remSleepPercentage != remSleepPercentage;
}
