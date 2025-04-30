# YOHO

Una aplicación móvil para monitorizar, analizar y mejorar la calidad del sueño utilizando datos de smartwatch.

## 📋 Descripción

YOHO es una aplicación desarrollada en Flutter que se conecta con tu smartwatch mediante la API Health Connect de Google para recopilar datos sobre tu sueño. La aplicación analiza estos datos para ofrecer estadísticas detalladas, predicciones personalizadas sobre la calidad del sueño y evaluación de riesgos de enfermedades asociadas.

## ✨ Características principales

- Monitorización de patrones de sueño mediante smartwatch
- Dashboard con visualización de métricas clave
- Análisis predictivo de calidad del sueño
- Evaluación de riesgos de salud basada en patrones de sueño
- Recomendaciones personalizadas para mejorar la calidad del descanso
- Interfaz minimalista y fácil de usar

## 🛠️ Tecnologías

- **Frontend**: Flutter/Dart
- **Backend**: Firebase (Firestore, Authentication)
- **Datos del smartwatch**: Health Connect API (Google)
- **Almacenamiento local**: Hive
- **Análisis de datos**: TensorFlow Lite
- **Gestión de estado**: flutter_bloc

## 📁 Estructura del proyecto

```
yoho/
├── lib/
│   ├── core/         # Utilidades, constantes, configuración
│   ├── data/         # Fuentes de datos, repositorios
│   ├── domain/       # Lógica de negocio, entidades
│   ├── presentation/ # UI, pantallas, widgets
│   └── ml/           # Modelos de predicción
```

## ⚙️ Requisitos

- Flutter 3.0+
- Dispositivo Android con soporte para Health Connect
- Smartwatch compatible
- Cuenta de Firebase (plan Spark para desarrollo)

## 🚀 Instalación y ejecución

1. Clona este repositorio:

   ```
   git clone https://github.com/usuario/sleephealth.git
   ```

2. Instala las dependencias:

   ```
   flutter pub get
   ```

3. Configura Firebase siguiendo las instrucciones en `docs/firebase_setup.md`

4. Ejecuta la aplicación:
   ```
   flutter run
   ```

## 👥 Equipo de desarrollo

- Desarrollador UI/UX
- Desarrollador Backend e integración Firebase
- Desarrollador Integración Health Connect
- Desarrollador Modelos de Predicción

## 📊 Estado del proyecto

Proyecto en fase de desarrollo como parte de un trabajo universitario.

---

_Nota: Este es un proyecto académico desarrollado para la Universidad Autonoma de Querétaro._
