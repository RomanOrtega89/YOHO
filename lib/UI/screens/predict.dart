import 'package:flutter/material.dart';
// import 'package:percent_indicator/percent_indicator.dart'; // Remove this import

// Relative path to SleepModelService
import '../../ml/SleepModelService.dart';
// Assumed paths for UserProfile and AggregatedHealthData.
// Ensure these files exist and correctly define the classes.
// The SleepModelService.dart imports UserProfile from '../UI/screens/settings.dart'
// and AggregatedHealthData from '../data/health_connect/health_connect.dart'.
// Adjusting paths relative to lib/UI/screens/predict.dart:
import './settings.dart'; // Assuming UserProfile is in lib/UI/screens/settings.dart
import '../../data/health_connect/health_service.dart'; // Assuming AggregatedHealthData is in lib/data/health_connect/health_connect.dart

class PredictionScreen extends StatefulWidget {
  final UserProfile userProfile;
  final AggregatedHealthData healthData;

  const PredictionScreen({
    Key? key,
    required this.userProfile,
    required this.healthData,
  }) : super(key: key);

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final SleepModelService _modelService = SleepModelService();
  Future<Map<String, double>>? _predictionFuture;

  late UserProfile _currentUserProfile;
  late AggregatedHealthData _currentHealthData;

  bool _predictionDisplayTrigger = false; // For animations

  @override
  void initState() {
    super.initState();
    _currentUserProfile = widget.userProfile;
    _currentHealthData = widget.healthData;
    _predictionDisplayTrigger = false;
    // Optionally, run prediction on init or wait for button press
    // _runPrediction();
  }

  Future<void> _runPrediction() async {
    UserProfile freshProfile = await ProfileService.loadProfile();
    // AggregatedHealthData freshHealthData = await HealthDataService.loadData(); // If needed

    setState(() {
      _predictionDisplayTrigger = false; // Reset animation trigger
      _currentUserProfile = freshProfile;
      // _currentHealthData = freshHealthData; // If health data is also refreshed

      _predictionFuture = _modelService.predict(
        _currentUserProfile,
        _currentHealthData,
      );
    });
  }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }

  String _formatSleepDuration(double totalHours) {
    if (totalHours < 0) totalHours = 0;
    int hours = totalHours.truncate();
    int minutes = ((totalHours - hours) * 60).round();
    return '${hours} h ${minutes.toString().padLeft(2, '0')} min';
  }

  String _mapSleepQualityToString(double qualityScore) {
    if (qualityScore <= 0) return "No disponible";
    if (qualityScore < 5) return 'Mala';
    if (qualityScore < 7) return 'Regular';
    if (qualityScore < 9) return 'Buena';
    return 'Excelente';
  }

  String _calculateAndFormatBmi(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 'N/A';
    double heightM = heightCm / 100.0;
    double bmi = weightKg / (heightM * heightM);
    return bmi.toStringAsFixed(
      1,
    ); // Using . for consistency, can be changed back to , if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Changed background to black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Adjusted padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                // Centering the button
                child: ElevatedButton(
                  onPressed: _runPrediction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor:
                        Colors.deepPurple, // Purple button from predict2
                    textStyle: const TextStyle(
                      fontSize: 20, // Text size from predict2
                      fontWeight: FontWeight.bold, // Kept bold for emphasis
                    ),
                  ),
                  child: const Text(
                    'Predecir', // Changed text from PREDECIR
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ), // Ensure text is white and matches size
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ), // Spacing from predict2 is 32, using 30 for consistency with old
              Expanded(
                child: FutureBuilder<Map<String, double>>(
                  future: _predictionFuture,
                  builder: (context, snapshot) {
                    if (_predictionFuture == null) {
                      return const Center(
                        child: Text(
                          'Presiona Predecir para ver los resultados.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null ||
                        snapshot.data!.containsKey('Error')) {
                      String errorMessage = 'Error al obtener la predicción.';
                      if (snapshot.hasError) {
                        errorMessage = 'Error: ${snapshot.error}';
                      } else if (snapshot.data?.containsKey('Error') ?? false) {
                        errorMessage =
                            'Error del modelo al procesar los datos. Verifica las entradas.';
                      }
                      // Reset trigger on error to allow re-animation on next success
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _predictionDisplayTrigger) {
                          setState(() {
                            _predictionDisplayTrigger = false;
                          });
                        }
                      });
                      return Center(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final results = snapshot.data!;
                    final double apneaProbability =
                        results['Sleep Apnea'] ?? 0.0;
                    final double insomniaProbability =
                        results['Insomnia'] ?? 0.0;

                    // Trigger animation display after data is loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_predictionDisplayTrigger) {
                        setState(() {
                          _predictionDisplayTrigger = true;
                        });
                      }
                    });

                    return SingleChildScrollView(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildAnimatedProbabilityCircle(
                                    'Apnea', // Label from predict2
                                    apneaProbability,
                                    const Color(
                                      0xFFE91E63,
                                    ), // Original pinkish color
                                  ),
                                  _buildAnimatedProbabilityCircle(
                                    'Insomnio', // Label from predict2
                                    insomniaProbability,
                                    const Color(
                                      0xFF00BCD4,
                                    ), // Original cyanis color
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Divider(color: Colors.white24),
                              const Text(
                                'Datos',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedOpacity(
                                opacity: _predictionDisplayTrigger ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeIn,
                                child:
                                    _buildDataSectionContent(), // Extracted content
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white24),
                              const Text(
                                'Recomendaciones',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedOpacity(
                                opacity: _predictionDisplayTrigger ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeIn,
                                child: const Text(
                                  'Basado en los resultados, se recomienda consultar a un especialista para una evaluación más detallada.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProbabilityCircle(
    String label,
    double probability,
    Color color,
  ) {
    // probability is 0.0 to 1.0
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: probability * 100,
      ), // Animate 0 to percentage
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // value is the animated percentage
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value:
                        value /
                        100, // Convert percentage back to 0.0-1.0 for indicator
                    strokeWidth: 10,
                    color: color,
                    backgroundColor: color.withOpacity(0.2),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Probabilidad',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ), // Slightly dimmer for subtitle
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Renamed from _buildDataSection to _buildDataSectionContent to avoid confusion
  // This now only returns the Column of data rows
  Widget _buildDataSectionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The "Datos" title is now outside this widget, directly in the Card
        _buildDataRow(
          icon: Icons.nightlight_round, // Icon from predict2
          label: 'Tiempo de sueño',
          value: _formatSleepDuration(_currentHealthData.avgSleepDurationHours),
        ),
        _buildDataRow(
          icon: Icons.bar_chart, // Icon from predict2
          label: 'Calidad del sueño',
          value: _mapSleepQualityToString(
            _currentHealthData.sleepQualityQuantified,
          ),
        ),
        _buildDataRow(
          icon: Icons.fitness_center, // Icon from predict2
          label: 'IMC',
          value: _calculateAndFormatBmi(
            _currentUserProfile.height,
            _currentUserProfile.weight,
          ),
        ),
        _buildDataRow(
          icon: Icons.favorite, // Icon from predict2
          label: 'Latidos por minuto',
          value: _currentHealthData.avgHeartRateBpm.round().toString(),
        ),
        _buildDataRow(
          icon: Icons.directions_walk_outlined,
          label: 'Pasos promedio',
          value: _currentHealthData.avgDailySteps.round().toString(),
        ),
        _buildDataRow(
          icon: Icons.cake, // Icon from predict2
          label: 'Edad',
          value: _currentUserProfile.age.toString(),
        ),
        _buildDataRow(
          icon: Icons.person, // Icon from predict2
          label: 'Género',
          value: _currentUserProfile.gender,
        ),
      ],
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // Padding from predict2
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.deepPurpleAccent,
            size: 28,
          ), // Style from predict2
          const SizedBox(width: 16), // Spacing from predict2
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ), // Style from predict2
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ), // Style from predict2
          ),
        ],
      ),
    );
  }
}
