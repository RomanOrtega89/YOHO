# etapa_3_convertir_tflite.py

import tensorflow as tf

# Cargar el modelo Keras
model = tf.keras.models.load_model("sleep_dnn_model.h5")

# Convertir a TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # optimización ligera
tflite_model = converter.convert()

# Guardar el modelo .tflite
with open("./YOHO/assets/model.tflite", "wb") as f:
    f.write(tflite_model)
