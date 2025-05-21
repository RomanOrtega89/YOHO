import 'package:flutter/material.dart';
import 'UI/screens/tracking.dart';
import 'UI/screens/statistics.dart';
import 'UI/screens/learn.dart';
import 'UI/screens/settings.dart'; // Provides UserProfile and ProfileService
import 'UI/screens/predict.dart'; // Import the PredictionScreen
import 'data/health_connect/health_service.dart'; // Provides AggregatedHealthData and HealthService

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOHO: sueño y salud',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[600],
          showUnselectedLabels: false,
          showSelectedLabels: true,
          type: BottomNavigationBarType.fixed, // Ensures all items are visible
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: Colors.grey[900],
        ).copyWith(secondary: Colors.blueAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;
  AggregatedHealthData? _aggregatedHealthData;
  bool _isLoading = true;
  String? _error;
  bool _errorDisplayed =
      false; // To prevent multiple snackbars for the same error

  final HealthService _healthService = HealthService();
  late List<Widget> _screenOptions;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await ProfileService.loadProfile();
      final healthDataMap =
          await _healthService.getAggregatedHealthDataForModel();

      final healthData = AggregatedHealthData(
        avgSleepDurationHours:
            healthDataMap['avg_sleep_duration_hours'] as double,
        sleepQualityQuantified:
            (healthDataMap['sleep_quality_quantified'] as int).toDouble(),
        avgHeartRateBpm:
            (healthDataMap['avg_heart_rate_bpm'] as int).toDouble(),
        avgDailySteps: healthDataMap['avg_daily_steps'] as int,
      );

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _aggregatedHealthData = healthData;
          _screenOptions = <Widget>[
            const TrackingScreen(),
            const StatisticsScreen(),
            const LearnScreen(),
            PredictionScreen(
              userProfile: _userProfile!,
              healthData: _aggregatedHealthData!,
            ),
            const SettingsScreen(),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data for HomeScreen: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          // Initialize _screenOptions with a fallback for PredictionScreen
          _screenOptions = <Widget>[
            const TrackingScreen(),
            const StatisticsScreen(),
            const LearnScreen(),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Predicción no disponible: Error al cargar datos.",
                  style: TextStyle(color: Colors.orangeAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SettingsScreen(),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If there was an error, _screenOptions is initialized with a fallback for PredictionScreen.
    // Display a SnackBar for the error if it hasn't been displayed yet.
    if (_error != null && !_errorDisplayed) {
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al cargar datos para predicción: $_error"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          // Set _errorDisplayed to true only after showing it,
          // or manage this flag based on whether the error is still relevant/user acknowledged it.
          // For simplicity here, we show it once per instance of error.
          if (mounted) {
            setState(() {
              _errorDisplayed = true;
            });
          }
        }
      });
    }

    return Scaffold(
      body: Center(child: _screenOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Seguimiento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nights_stay),
            label: 'Aprender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.online_prediction),
            label: 'Predecir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // type: BottomNavigationBarType.fixed, // Already set in ThemeData
      ),
    );
  }
}
