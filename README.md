# YOHO

Una aplicación móvil para monitorizar, analizar y mejorar la calidad del sueño utilizando datos de smartwatch.

## 📋 Descripción

YOHO es una aplicación desarrollada en Flutter que se conecta con tu smartwatch mediante la API Health Connect de Google para recopilar datos sobre tu sueño. La aplicación analiza estos datos para ofrecer estadísticas detalladas, predicciones personalizadas sobre la calidad del sueño y evaluación de riesgos de enfermedades asociadas.

## ✨ Características principales

- Monitorización de patrones de sueño mediante smartwatch
- Dashboard con visualización de métricas clave
- Análisis predictivo de calidad del sueño (en fase de implementación)
- Evaluación de riesgos de salud basada en patrones de sueño (en fase de implementación)
- Recomendaciones personalizadas para mejorar la calidad del descanso
- Interfaz minimalista y fácil de usar

## 🛠️ Tecnologías

- **Frontend**: Flutter/Dart
- **Backend**: Dart
- **Datos del smartwatch**: Health Connect API (Google)
- **Análisis de datos**: TensorFlow Lite (Modelo de predicción mediante Redes Neuronales Profundas - DNN)

## 📁 Estructura del proyecto

```
yoho/
├── lib/
│   ├── data/         # Fuentes de datos, lectura de datos
│   ├── UI/           # UI, pantallas, widgets
│   └── ml/           # Modelos de predicción

```

## 🧠 Modelo de Predicción y Conjunto de Datos

Para el análisis predictivo de la calidad del sueño y la evaluación de riesgos de salud, se utilizará un modelo de Redes Neuronales Profundas (DNN) implementado con TensorFlow Lite. Este modelo se entrenará con el siguiente conjunto de datos:

### Sleep Health and Lifestyle Dataset

**Autor:** Laksika Tharmalingam  
**Enlace al dataset:** [Sleep Health and Lifestyle Dataset en Kaggle](https://www.kaggle.com/datasets/uom190346a/sleep-health-and-lifestyle-dataset)

**Descripción General del Dataset:**
El "Sleep Health and Lifestyle Dataset" consta de 400 registros y 13 columnas, abarcando una amplia gama de variables relacionadas con el sueño y los hábitos diarios. Incluye detalles como género, edad, ocupación, duración del sueño, calidad del sueño, nivel de actividad física, niveles de estrés, categoría de IMC, presión arterial, frecuencia cardíaca, pasos diarios y la presencia o ausencia de trastornos del sueño.

**Características Clave del Dataset:**
-   **Métricas Completas de Sueño:** Explora la duración del sueño, la calidad y los factores que influyen en los patrones de sueño.
-   **Factores de Estilo de Vida:** Analiza los niveles de actividad física, los niveles de estrés y las categorías de IMC.
-   **Salud Cardiovascular:** Examina las mediciones de presión arterial y frecuencia cardíaca.
-   **Análisis de Trastornos del Sueño:** Identifica la ocurrencia de trastornos del sueño como Insomnio y Apnea del Sueño.

**Columnas del Dataset:**

-   **Person ID:** Un identificador para cada individuo.
-   **Gender:** El género de la persona (Masculino/Femenino).
-   **Age:** La edad de la persona en años.
-   **Occupation:** La ocupación o profesión de la persona.
-   **Sleep Duration (hours):** El número de horas que la persona duerme por día.
-   **Quality of Sleep (scale: 1-10):** Una calificación subjetiva de la calidad del sueño, en una escala de 1 a 10.
-   **Physical Activity Level (minutes/day):** El número de minutos que la persona realiza actividad física diariamente.
-   **Stress Level (scale: 1-10):** Una calificación subjetiva del nivel de estrés experimentado por la persona, en una escala de 1 a 10.
-   **BMI Category:** La categoría de IMC de la persona (p. ej., Bajo peso, Normal, Sobrepeso).
-   **Blood Pressure (systolic/diastolic):** La medición de la presión arterial de la persona, indicada como presión sistólica sobre presión diastólica.
-   **Heart Rate (bpm):** La frecuencia cardíaca en reposo de la persona en latidos por minuto.
-   **Daily Steps:** El número de pasos que la persona da por día.
-   **Sleep Disorder:** La presencia o ausencia de un trastorno del sueño en la persona (Ninguno, Insomnio, Apnea del Sueño).

**Detalles sobre la Columna "Sleep Disorder":**

-   **None:** El individuo no presenta ningún trastorno específico del sueño.
-   **Insomnia:** El individuo experimenta dificultad para conciliar el sueño o mantenerse dormido, lo que lleva a un sueño inadecuado o de mala calidad.
-   **Sleep Apnea:** El individuo sufre pausas en la respiración durante el sueño, lo que resulta en patrones de sueño interrumpidos y riesgos potenciales para la salud.

## ⚙️ Requisitos

- Flutter 3.0+
- Dispositivo Android con soporte para Health Connect
- Android 9.0 en adelante
- Smartwatch compatible

## 🚀 Instalación y ejecución

### Desde el código fuente

1. Clona este repositorio:

   ```
   git clone https://github.com//RomanOrtega89/YOHO.git
   ```

2. Instala las dependencias:

   ```
   flutter pub get
   ```

3. Ejecuta la aplicación:
   ```
   flutter run
   ```

### Instalación en Android (APK)

1. Descarga el archivo `yoho-v0.0.2.apk` desde la sección de [Releases de GitHub](https://github.com//RomanOrtega89/YOHO/releases).
2. Transfiere el archivo APK a tu dispositivo Android.
3. En tu dispositivo Android, permite la instalación de aplicaciones de fuentes desconocidas (si aún no está habilitado).
4. Abre el explorador de archivos, localiza el archivo APK y pulsa sobre él para instalar la aplicación.
5. **Importante:** Asegúrate de tener instalada la aplicación [Health Connect de Google](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata) y haberla sincronizado con tus aplicaciones de fitness compatibles (por ejemplo, Google Fit, Samsung Health, Fitbit, Mi Fitness, etc.) para que YOHO pueda acceder a los datos.

## 👥 Equipo de desarrollo

- Román Ortega Muñoz
- René Tellez Carmona

## 📊 Estado del proyecto

Proyecto en fase de desarrollo como parte de un trabajo universitario.

---

_Nota: Este es un proyecto académico desarrollado para la Universidad Autónoma de Querétaro._
