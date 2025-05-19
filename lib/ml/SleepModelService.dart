// lib/services/sleep_model_service.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
// Importa tus modelos de datos
import '../UI/screens/settings.dart'; // Para UserProfile
import '../data/health_connect/health_service.dart'; // Ajusta el path

class SleepModelService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // --- PARÁMETROS DE PREPROCESAMIENTO (COPIA EXACTAMENTE DE LA SALIDA DE PYTHON) ---
  // Orden numérico: ['Age', 'Sleep Duration', 'Quality of Sleep', 'Heart Rate', 'Daily Steps']
  // Orden numérico: ['Age', 'Sleep Duration', 'Quality of Sleep', 'Heart Rate', 'Daily Steps']
  final List<double> _means = const [
    42.26086956521739,
    7.13979933110368,
    7.317725752508361,
    69.8628762541806,
    6872.57525083612,
  ];
  final List<double> _stdDevs = const [
    8.569927231637502,
    0.7895563886358421,
    1.1806920105535434,
    3.526952091858574,
    1613.0893489456166,
  ];

  // Orden categórico: ['Gender', 'BMI Category']
  // Gender: ['Female', 'Male']
  final List<String> _genderCategories = const ['Female', 'Male'];
  // BMI Category: ['Normal', 'Obese', 'Overweight']
  final List<String> _bmiCategories = const ['Normal', 'Obese', 'Overweight'];

  // Orden de clases de salida (de target_encoder.categories_ en Python)
  // Ejemplo: ['Insomnia', 'None', 'Sleep Apnea']
  final List<String> _outputClasses = const ['Insomnia', 'None', 'Sleep Apnea'];
  // --- FIN PARÁMETROS ---

  // Nombre de las características en el orden que el modelo espera (obtenido de Python)
  // ['Age', 'Sleep Duration', 'Quality of Sleep', 'Heart Rate', 'Daily Steps', 'Gender_Female', 'Gender_Male', 'BMI Category_Normal', 'BMI Category_Obese', 'BMI Category_Overweight']
  // Esta lista es solo para referencia y para asegurar la lógica de preprocesamiento.
  // El número total de características debe coincidir con la entrada del modelo.

  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/sleep_disorder_model_yoho.tflite',
      );
      // _interpreter.allocateTensors(); // allocateTensors se llama implícitamente por run
      _isModelLoaded = true;
      print('Modelo TFLite cargado exitosamente.');
    } catch (e) {
      print('Error al cargar el modelo TFLite: $e');
      _isModelLoaded = false;
    }
  }

  String _getBmiCategory(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) {
      // Devuelve la categoría más común o una por defecto si los datos son inválidos
      return _bmiCategories.contains('Normal') ? 'Normal' : _bmiCategories[0];
    }
    double heightM = heightCm / 100.0;
    double bmi = weightKg / (heightM * heightM);

    if (bmi < 18.5) {
      // Si 'Underweight' no está en _bmiCategories, mapear a 'Normal' o la más adecuada
      return _bmiCategories.contains('Underweight')
          ? 'Underweight'
          : (_bmiCategories.contains('Normal') ? 'Normal' : _bmiCategories[0]);
    } else if (bmi < 25) {
      return 'Normal';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  List<double> _preprocessInput(
    UserProfile profile,
    AggregatedHealthData healthData,
  ) {
    List<double> processedInput = [];

    // --- Características Numéricas (Normalizadas/Estandarizadas) ---
    // 1. Age
    processedInput.add((profile.age.toDouble() - _means[0]) / _stdDevs[0]);
    // 2. Sleep Duration (avgSleepDurationHours de Health Connect)
    processedInput.add(
      (healthData.avgSleepDurationHours - _means[1]) / _stdDevs[1],
    );
    // 3. Quality of Sleep (sleepQualityQuantified de Health Connect)
    processedInput.add(
      (healthData.sleepQualityQuantified.toDouble() - _means[2]) / _stdDevs[2],
    );
    // 4. Heart Rate (avgHeartRateBpm de Health Connect)
    processedInput.add(
      (healthData.avgHeartRateBpm.toDouble() - _means[3]) / _stdDevs[3],
    );
    // 5. Daily Steps (avgDailySteps de Health Connect)
    processedInput.add(
      (healthData.avgDailySteps.toDouble() - _means[4]) / _stdDevs[4],
    );

    // --- Características Categóricas (Codificadas One-Hot) ---
    // Gender
    String userGender = profile.gender; // "Masculino", "Femenino", "No binario"
    String mappedGender =
        "Other"; // Por si no coincide con las categorías entrenadas
    if (userGender == 'Masculino') mappedGender = 'Male';
    if (userGender == 'Femenino') mappedGender = 'Female';

    for (String category in _genderCategories) {
      processedInput.add(mappedGender == category ? 1.0 : 0.0);
    }

    // BMI Category
    String bmiCategory = _getBmiCategory(profile.height, profile.weight);
    for (String category in _bmiCategories) {
      processedInput.add(bmiCategory == category ? 1.0 : 0.0);
    }

    // Es crucial que el número total de elementos en processedInput coincida con
    // la forma de entrada esperada por el modelo.
    // Ejemplo: 5 numéricas + 2 (gender) + 3 (BMI) = 10 características.
    // print("Entrada preprocesada para el modelo (longitud ${processedInput.length}): $processedInput");
    return processedInput;
  }

  Future<Map<String, double>> predict(
    UserProfile profile,
    AggregatedHealthData healthData,
  ) async {
    await loadModel(); // Asegura que el modelo esté cargado
    if (!_isModelLoaded || _interpreter == null) {
      print('Error: Intérprete del modelo no está cargado.');
      // Devuelve un mapa indicando el error y las probabilidades como 0 o NaN
      return Map.fromIterable(_outputClasses, key: (k) => k, value: (_) => 0.0)
        ..['Error'] = 1.0;
    }

    final List<double> modelInputList = _preprocessInput(profile, healthData);

    // El modelo espera una entrada de forma [1, N] donde N es el número de características.
    // La forma de entrada se puede verificar con _interpreter.getInputTensor(0).shape
    // Ejemplo: si N=10, la forma es [1, 10]
    final inputTensor = Float32List.fromList(modelInputList);
    // Crear un buffer para la entrada con la forma correcta [1, num_features]
    final reshapedInput = inputTensor.reshape([1, modelInputList.length]);

    // La salida será de forma [1, M] donde M es el número de clases (ej. 3).
    // _interpreter.getOutputTensor(0).shape te dará la forma, ej: [1, 3]
    var outputShape = _interpreter!.getOutputTensor(0).shape;
    var outputBuffer = List.filled(
      outputShape.reduce((a, b) => a * b),
      0.0,
    ).reshape(outputShape); // Crea List<List<double>> ej: [[0.0, 0.0, 0.0]]

    try {
      _interpreter!.run(reshapedInput, outputBuffer);
    } catch (e) {
      print("Error al ejecutar la inferencia del modelo: $e");
      return Map.fromIterable(_outputClasses, key: (k) => k, value: (_) => 0.0)
        ..['Error'] = 1.0;
    }

    final List<double> probabilities =
        outputBuffer[0]; // La primera (y única) lista de probabilidades

    Map<String, double> results = {};
    for (int i = 0; i < _outputClasses.length; i++) {
      results[_outputClasses[i]] = probabilities[i];
    }

    // print("Resultados de la predicción (probabilidades): $results");
    return results;
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
    print("Intérprete del modelo cerrado.");
  }
}
