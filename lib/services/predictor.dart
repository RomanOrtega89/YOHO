import 'package:tflite_flutter/tflite_flutter.dart';

class SleepPredictor {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('model.tflite');
  }

  Future<double> predict(List<double> inputFeatures) async {
    final input = [inputFeatures];
    final output = List.filled(1, 0.0).reshape([1, 1]);

    _interpreter.run(input, output);
    return output[0][0]; // probabilidad
  }
}
