# etapa_1_preprocesamiento.py

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# Cargar datos
df = pd.read_csv("./YOHO/lib/data/Sleep_health_clean.csv")

# Crear etiqueta binaria
df['target'] = df['Sleep Disorder'].apply(
    lambda x: 0 if pd.isna(x) or x == 'None' else 1)

# Filtrar columnas requeridas
df = df[['Gender', 'Age', 'Sleep Duration', 'Quality of Sleep',
         'BMI Category', 'Blood Pressure', 'Heart Rate',
         'Daily Steps', 'Sleep Disorder', 'target']]

# Separar presión sistólica y diastólica
df[['Systolic', 'Diastolic']] = df['Blood Pressure'].str.split(
    '/', expand=True)
df['Systolic'] = pd.to_numeric(df['Systolic'], errors='coerce')
df['Diastolic'] = pd.to_numeric(df['Diastolic'], errors='coerce')
df = df.drop(columns=['Blood Pressure', 'Sleep Disorder'])

# Codificar variables categóricas
df = pd.get_dummies(df, columns=['Gender', 'BMI Category'], drop_first=True)

# Separar entrada y salida
X = df.drop(columns=['target'])
y = df['target']

# Normalización
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# División de datos
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, random_state=42)

# Confirmación
print(
    f"✅ Preprocesamiento completado. X_train: {X_train.shape}, X_test: {X_test.shape}")
