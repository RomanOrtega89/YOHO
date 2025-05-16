# etapa_2_entrenamiento.py

import tensorflow as tf
from tensorflow.keras import layers, models
from etapa_1_preprocesamiento import X_train, y_train, X_test, y_test

# Arquitectura mejorada
model = models.Sequential([
    layers.Input(shape=(X_train.shape[1],)),
    layers.Dense(128, activation='relu'),
    layers.BatchNormalization(),
    layers.Dropout(0.4),
    layers.Dense(64, activation='relu'),
    layers.BatchNormalization(),
    layers.Dropout(0.3),
    layers.Dense(1, activation='sigmoid')  # Salida binaria
])

model.compile(optimizer='adam',
              loss='binary_crossentropy',
              metrics=['accuracy'])

# Entrenamiento
history = model.fit(X_train, y_train,
                    epochs=40,
                    batch_size=16,
                    validation_split=0.2,
                    verbose=1)

# Evaluación
loss, acc = model.evaluate(X_test, y_test)
print(f"Precisión del modelo en test: {acc:.4f}")

# Guardar modelo
model.save("sleep_dnn_model.h5")
