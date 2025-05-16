import 'package:flutter/material.dart';
import '../../services/predictor.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final predictor = SleepPredictor();
  double? result;
  bool modelLoaded = false;

  // Ejemplo de entrada normalizada: debe coincidir con el preprocesamiento
  final List<double> input = [
    0.25, 0.12, -0.37, 0.44, 0.31, -0.22, 0.56, 1.0,
    0.0, // 9 features normalizadas
  ];

  @override
  void initState() {
    super.initState();
    predictor.loadModel().then((_) {
      setState(() {
        modelLoaded = true;
      });
    });
  }

  void _predict() async {
    final prob = await predictor.predict(input);
    setState(() {
      result = prob;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Predicción de Trastorno del Sueño")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!modelLoaded) const CircularProgressIndicator(),
            if (modelLoaded) ...[
              Text(
                result == null
                    ? 'Presiona el botón para predecir'
                    : 'Probabilidad: ${(result! * 100).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _predict,
                child: const Text('Predecir'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
