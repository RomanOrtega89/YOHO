import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping
import numpy as np
import joblib # Para guardar los objetos de preprocesamiento

# --- Configuración ---
# Características a usar del CSV (deben tener correspondencia con los datos de la app)
# Se omiten 'Physical Activity Level' y 'Stress Level' por no tener un mapeo directo y simple
# con los datos disponibles de la app.
# 'Blood Pressure' también se omite. 'Occupation' también.
SELECTED_FEATURES = ['Gender', 'Age', 'Sleep Duration', 'Quality of Sleep', 'BMI Category', 'Heart Rate', 'Daily Steps']
TARGET_VARIABLE = 'Sleep Disorder'

# --- 1. Carga y Limpieza Inicial de Datos ---
try:
    df = pd.read_csv('lib/data/Sleep_health_clean.csv')
except FileNotFoundError:
    print("Error: El archivo 'lib/data/Sleep_health_clean.csv' no fue encontrado.")
    print("Asegúrate de que el path sea correcto o coloca el archivo en la raíz del script y usa 'Sleep_health_clean.csv'.")
    exit()


df_model = df[SELECTED_FEATURES + [TARGET_VARIABLE]].copy()

# --- 2. Preprocesamiento de Datos ---

# Manejar valores NaN en la columna objetivo (interpretarlos como 'None')
df_model[TARGET_VARIABLE] = df_model[TARGET_VARIABLE].fillna('None')

# Filtrar solo las clases de interés para la predicción
valid_disorders = ['None', 'Sleep Apnea', 'Insomnia']
df_model = df_model[df_model[TARGET_VARIABLE].isin(valid_disorders)]

# Simplificar 'BMI Category': Unir 'Normal Weight' con 'Normal'
print(f"Valores únicos de 'BMI Category' ANTES de reemplazo: {df_model['BMI Category'].unique()}")
df_model['BMI Category'] = df_model['BMI Category'].replace({'Normal Weight': 'Normal'})
# Considerar si 'Underweight' existe y cómo manejarlo (aquí asumimos que no es una categoría principal o se mapea si es necesario)
print(f"Valores únicos de 'BMI Category' DESPUÉS de reemplazo: {df_model['BMI Category'].unique()}")


# Definir X (características) e y (objetivo)
X = df_model[SELECTED_FEATURES]
y_categorical = df_model[TARGET_VARIABLE]

# Codificar la variable objetivo (y) a one-hot
target_encoder = OneHotEncoder(sparse_output=False, handle_unknown='ignore')
y_encoded = target_encoder.fit_transform(y_categorical.values.reshape(-1, 1))
print(f"Codificador de la variable objetivo ('{TARGET_VARIABLE}') entrenado.")
print(f"Categorías objetivo (orden de salida del modelo): {target_encoder.categories_[0]}")


# Definir transformadores para preprocesamiento de características
numeric_features = ['Age', 'Sleep Duration', 'Quality of Sleep', 'Heart Rate', 'Daily Steps']
numeric_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='mean')), # Imputa NaNs con la media
    ('scaler', StandardScaler()) # Normaliza (estandariza)
])

categorical_features = ['Gender', 'BMI Category']
categorical_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='most_frequent')), # Imputa NaNs con el más frecuente
    ('onehot', OneHotEncoder(handle_unknown='ignore', sparse_output=False)) # Codificación One-Hot
])

# Crear el preprocesador ColumnTransformer
preprocessor = ColumnTransformer(
    transformers=[
        ('num', numeric_transformer, numeric_features),
        ('cat', categorical_transformer, categorical_features)
    ],
    remainder='passthrough' # Mantiene columnas no especificadas (si las hubiera, aquí no debería haber)
)

# Dividir los datos ANTES de aplicar 'fit' al preprocesador para evitar fuga de datos del test set
X_train, X_test, y_train, y_test = train_test_split(X, y_encoded, test_size=0.2, random_state=42, stratify=y_categorical) # stratify por y original

# Aplicar el preprocesador: ajustar en entrenamiento, solo transformar en test
X_train_processed = preprocessor.fit_transform(X_train)
X_test_processed = preprocessor.transform(X_test)

print(f"Preprocesador de características entrenado.")
print(f"Forma de X_train_processed: {X_train_processed.shape}")
print(f"Forma de y_train: {y_train.shape}")

# Guardar el preprocesador y el codificador de target para uso futuro (opcional, pero bueno para la reproducibilidad)
joblib.dump(preprocessor, 'preprocessor_yoho.joblib')
joblib.dump(target_encoder, 'target_encoder_yoho.joblib')
print("Preprocesador y codificador de target guardados como 'preprocessor_yoho.joblib' y 'target_encoder_yoho.joblib'")

# --- Información para la App Flutter ---
print("\n--- PARÁMETROS DE PREPROCESAMIENTO PARA FLUTTER ---")
# Medias y escalas de StandardScaler
numeric_pipeline = preprocessor.named_transformers_['num']
scaler = numeric_pipeline.named_steps['scaler']
print(f"Medias para características numéricas (orden: {numeric_features}): \n{scaler.mean_.tolist()}")
print(f"Escalas (std dev) para características numéricas (orden: {numeric_features}): \n{scaler.scale_.tolist()}")

# Categorías de OneHotEncoder
categorical_pipeline = preprocessor.named_transformers_['cat']
onehot_encoder_cats = categorical_pipeline.named_steps['onehot']
print("\nCategorías para OneHotEncoder (en orden de `categorical_features`):")
for i, feature in enumerate(categorical_features):
    print(f"  {feature}: {onehot_encoder_cats.categories_[i].tolist()}")

# Nombres de las características después del preprocesamiento (para verificar el orden final)
feature_names_out = []
# Nombres de características numéricas (permanecen igual en orden)
feature_names_out.extend(numeric_features)
# Nombres de características categóricas (después de one-hot)
cat_onehot_feature_names = preprocessor.named_transformers_['cat'].named_steps['onehot'].get_feature_names_out(categorical_features)
feature_names_out.extend(cat_onehot_feature_names)
print(f"\nOrden final de las características de entrada al modelo ({len(feature_names_out)} columnas): \n{feature_names_out}")
print(f"Esto debe coincidir con X_train_processed.shape[1] = {X_train_processed.shape[1]}")
print("--- FIN PARÁMETROS ---")

# --- 3. Construcción del Modelo DNN ---
model = Sequential([
    Dense(128, activation='relu', input_shape=(X_train_processed.shape[1],)),
    Dropout(0.4), # Aumentado Dropout
    Dense(64, activation='relu'),
    Dropout(0.4), # Aumentado Dropout
    Dense(32, activation='relu'),
    Dense(y_train.shape[1], activation='softmax') # y_train.shape[1] es el número de clases
])

model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.001), # Adam es un buen optimizador por defecto
            loss='categorical_crossentropy', # Adecuado para clasificación multiclase one-hot
            metrics=['accuracy'])

model.summary()

# --- 4. Entrenamiento del Modelo ---
early_stopping = EarlyStopping(monitor='val_loss', patience=15, restore_best_weights=True, verbose=1) # Aumentada paciencia
history = model.fit(X_train_processed, y_train,
                    epochs=150, # Aumentadas épocas, EarlyStopping se encargará
                    batch_size=32, # Batch size común
                    validation_split=0.2, # Usar una parte del training set para validación interna
                    callbacks=[early_stopping],
                    verbose=2)

# Evaluar el modelo con el conjunto de test
loss, accuracy = model.evaluate(X_test_processed, y_test, verbose=0)
print(f"\nModelo Entrenado. Precisión en Test: {accuracy*100:.2f}% | Pérdida en Test: {loss:.4f}")

# --- 5. Guardar el modelo Keras y Convertir a TensorFlow Lite ---
model.save('sleep_disorder_model_yoho.h5')
print("Modelo Keras guardado como 'sleep_disorder_model_yoho.h5'")

# Convertir el modelo Keras a TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT] # Optimiza para tamaño y latencia
tflite_model = converter.convert()

# Guardar el modelo TFLite
tflite_model_path = 'sleep_disorder_model_yoho.tflite'
with open(tflite_model_path, 'wb') as f:
    f.write(tflite_model)
print(f"Modelo TensorFlow Lite guardado como '{tflite_model_path}'")

# (Opcional) Verificar detalles del modelo TFLite
# interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
# interpreter.allocate_tensors()
# print("\nDetalles de entrada del modelo TFLite:", interpreter.get_input_details())
# print("Detalles de salida del modelo TFLite:", interpreter.get_output_details())