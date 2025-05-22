import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SettingsScreenBackground extends StatelessWidget {
  const SettingsScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: const [Background(), SettingsContent()]),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(child: SettingsOptionsList());
  }
}

// Fondo de la aplicación con gradiente y efectos visuales
class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black);
  }
}

class SoftWave extends StatelessWidget {
  final Color color;

  const SoftWave({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(150),
          color: color,
        ),
      ),
    );
  }
}

// Título de la sección de configuración
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[900],
        centerTitle: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Background(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 25), // Espacio bajo el AppBar
              child: const SettingsOptionsList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Lista de opciones de configuración
class SettingsOptionsList extends StatelessWidget {
  const SettingsOptionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsItem(
          icon: Icons.person_outline,
          title: 'Mi perfil',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.settings_outlined,
          title: 'Ajustes generales',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeneralSettingsPage()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.help_outline,
          title: 'Preguntas frecuentes',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FAQPage()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Políticas de privacidad',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.favorite, // Nuevo ícono para presión arterial
          title: 'Presión arterial',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BloodPressurePage()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.monitor_weight, // Nuevo ícono para IMC
          title: 'IMC',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IMCPage()),
            );
          },
        ),
      ],
    );
  }
}

// Elemento individual de configuración
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFF373954).withOpacity(0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }
}

// Página de Políticas de Privacidad
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  Future<String> loadPrivacyPolicy() async {
    try {
      return await rootBundle.loadString('assets/POLÍTICA DE PRIVACIDAD.txt');
    } catch (e) {
      return 'Error al cargar el archivo de política de privacidad. Por favor, contacte con soporte.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Políticas de Privacidad'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          const Background(),
          FutureBuilder<String>(
            future: loadPrivacyPolicy(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Error al cargar el archivo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      snapshot.data ?? '',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'icon': Icons.track_changes,
        'question': '¿Cómo puedo realizar un seguimiento de mi progreso?',
        'answer':
            'En la sección Seguimiento, puedes ver tu progreso diario y semanal. Asegúrate de registrar tus actividades regularmente para obtener estadísticas precisas.',
      },
      {
        'icon': Icons.bar_chart,
        'question': '¿Cómo se calculan las estadísticas en la aplicación?',
        'answer':
            'Las estadísticas se calculan en base a los datos que recopilamos a través de Health Connect. Esto incluye tus horas de sueño, fases y otros parámetros relevantes.',
      },
      {
        'icon': Icons.person,
        'question': '¿Cómo puedo actualizar mi perfil?',
        'answer':
            'Para actualizar tu perfil, ve a Configuraciones > Mi Perfil. Aquí puedes cambiar tu nombre, género, edad y otros datos personales.',
      },
      {
        'icon': Icons.support_agent,
        'question': '¿Cómo puedo contactar al soporte técnico?',
        'answer':
            'Puedes contactar al soporte técnico enviando un correo a soporte@yoho-health.com.',
      },
      {
        'icon': Icons.privacy_tip,
        'question': '¿Dónde puedo encontrar las políticas de privacidad?',
        'answer':
            'Las políticas de privacidad están disponibles en Configuración > Políticas de Privacidad. Aquí puedes leer sobre cómo manejamos tus datos y protegemos tu privacidad.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          const Background(),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.grey[900],
                child: ExpansionTile(
                  leading: Icon(
                    faq['icon'] as IconData,
                    color: Colors.deepPurpleAccent,
                  ),
                  title: Text(
                    faq['question'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        faq['answer'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Página de Ajustes Generales
class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  bool notificationsEnabled = true;
  String selectedTheme = 'Oscuro';
  String selectedLanguage = 'Español';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes Generales'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          const Background(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Notificaciones',
                    style: TextStyle(color: Colors.black87),
                  ),
                  subtitle: const Text(
                    'Activar o desactivar notificaciones',
                    style: TextStyle(color: Colors.black54),
                  ),
                  value: notificationsEnabled,
                  activeColor: Colors.grey,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text(
                    'Tema',
                    style: TextStyle(color: Colors.black87),
                  ),
                  subtitle: Text(
                    selectedTheme,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: const Icon(Icons.brightness_4, color: Colors.grey),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Seleccionar Tema'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Claro'),
                                  onTap: () {
                                    setState(() {
                                      selectedTheme = 'Claro';
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('Oscuro'),
                                  onTap: () {
                                    setState(() {
                                      selectedTheme = 'Oscuro';
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text(
                    'Idioma',
                    style: TextStyle(color: Colors.black87),
                  ),
                  subtitle: Text(
                    selectedLanguage,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: const Icon(Icons.language, color: Colors.grey),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Seleccionar Idioma'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Español'),
                                  onTap: () {
                                    setState(() {
                                      selectedLanguage = 'Español';
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('English'),
                                  onTap: () {
                                    setState(() {
                                      selectedLanguage = 'English';
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text(
                    'Restablecer configuración',
                    style: TextStyle(color: Colors.black87),
                  ),
                  subtitle: const Text(
                    'Volver a los valores predeterminados',
                    style: TextStyle(color: Colors.black54),
                  ),
                  trailing: const Icon(Icons.restore, color: Colors.grey),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Restablecer configuración'),
                            content: const Text(
                              '¿Estás seguro de que deseas restablecer todas las configuraciones a sus valores predeterminados?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    notificationsEnabled = true;
                                    selectedTheme = 'Oscuro';
                                    selectedLanguage = 'Español';
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Configuración restablecida',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Restablecer'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Página de Perfil
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// Modelo de datos para el perfil de usuario
class UserProfile {
  String name;
  int age;
  double height;
  double weight;
  String gender;

  UserProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
  });

  // Convertir a Map para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
    };
  }

  // Crear desde Map (para cargar desde SharedPreferences)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Manejo seguro de conversiones
    int age = 25;
    if (json['age'] is int) {
      age = json['age'] as int;
    } else if (json['age'] is String) {
      age = int.tryParse(json['age'] as String) ?? 25;
    }

    double height = 170.0;
    if (json['height'] is double) {
      height = json['height'] as double;
    } else if (json['height'] is int) {
      height = (json['height'] as int).toDouble();
    } else if (json['height'] is String) {
      height = double.tryParse(json['height'] as String) ?? 170.0;
    }

    double weight = 70.0;
    if (json['weight'] is double) {
      weight = json['weight'] as double;
    } else if (json['weight'] is int) {
      weight = (json['weight'] as int).toDouble();
    } else if (json['weight'] is String) {
      weight = double.tryParse(json['weight'] as String) ?? 70.0;
    }

    return UserProfile(
      name: json['name'] as String? ?? 'Usuario',
      age: age,
      height: height,
      weight: weight,
      gender: json['gender'] as String? ?? 'No especificado',
    );
  }

  // Convertir datos para usar con TensorFlow Lite
  // Esta función es útil incluso antes de implementar TensorFlow
  List<double> toModelInput() {
    // Ajusta esto según las entradas específicas que necesite tu modelo
    List<double> modelInput = [];

    // Agregar edad normalizada (suponiendo un rango de 0 a 100)
    modelInput.add(age / 100.0);

    // Agregar altura normalizada (suponiendo un rango de 0 a 250 cm)
    modelInput.add(height / 250.0);

    // Agregar peso normalizado (suponiendo un rango de 0 a 200 kg)
    modelInput.add(weight / 200.0);

    // Codificar género como valor numérico
    double genderValue = 0.0;
    switch (gender) {
      case 'Masculino':
        genderValue = 0.0;
        break;
      case 'Femenino':
        genderValue = 1.0;
        break;
      case 'No binario':
        genderValue = 2.0;
        break;
      default:
        genderValue = 3.0;
    }
    modelInput.add(genderValue / 3.0); // Normalizado

    return modelInput;
  }
}

// Servicio para manejar el almacenamiento y recuperación del perfil
class ProfileService {
  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar cada valor individualmente con su tipo adecuado
    await prefs.setString('name', profile.name);
    await prefs.setInt('age', profile.age);
    await prefs.setDouble('height', profile.height);
    await prefs.setDouble('weight', profile.weight);
    await prefs.setString('gender', profile.gender);

    try {
      // También guardar todo el objeto como JSON para futuras extensiones
      final jsonProfile = profile.toJson();
      await prefs.setString('user_profile', jsonEncode(jsonProfile));
    } catch (e) {
      // ignore: avoid_print
      print('Error al guardar el perfil completo como JSON: $e');
      // Si falla el guardado como JSON, los valores individuales ya se guardaron
    }
  }

  static Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // Intentar cargar el perfil completo primero
    final jsonString = prefs.getString('user_profile');
    if (jsonString != null) {
      try {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserProfile.fromJson(jsonMap);
      } catch (e) {
        // Si hay error, usar el método de respaldo
        // ignore: avoid_print
        print('Error al decodificar el perfil: $e');
      }
    }

    // Método de respaldo: cargar individualmente y hacer conversiones seguras
    String name = prefs.getString('name') ?? 'Usuario';

    // Conversión segura de strings a números
    int age = 25;
    try {
      String? ageStr = prefs.getString('age');
      if (ageStr != null) {
        age = int.parse(ageStr);
      } else {
        // Intentar obtener directo como int si está guardado así
        int? ageInt = prefs.getInt('age');
        if (ageInt != null) age = ageInt;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error convirtiendo edad: $e');
    }

    double height = 170.0;
    try {
      String? heightStr = prefs.getString('height');
      if (heightStr != null) {
        height = double.parse(heightStr);
      } else {
        // Intentar obtener directo como double si está guardado así
        double? heightDouble = prefs.getDouble('height');
        if (heightDouble != null) height = heightDouble;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error convirtiendo altura: $e');
    }

    double weight = 70.0;
    try {
      String? weightStr = prefs.getString('weight');
      if (weightStr != null) {
        weight = double.parse(weightStr);
      } else {
        // Intentar obtener directo como double si está guardado así
        double? weightDouble = prefs.getDouble('weight');
        if (weightDouble != null) weight = weightDouble;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error convirtiendo peso: $e');
    }

    String gender = prefs.getString('gender') ?? 'No especificado';

    return UserProfile(
      name: name,
      age: age,
      height: height,
      weight: weight,
      gender: gender,
    );
  }
}

// Servicio para integrar con TensorFlow Lite (preparado para implementación futura)
class MLService {
  static Future<List<dynamic>> runInference(UserProfile profile) async {
    try {
      final modelInput = profile.toModelInput();

      print('Datos preparados para ML (simulando inferencia): $modelInput');
      return [0.75, 0.25]; // Datos simulados - ajustar según lo esperado
    } catch (e) {
      // ignore: avoid_print
      print('Error al preparar datos para ML: $e');
      return [];
    }
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController(text: 'Usuario');
  final ageController = TextEditingController(text: '25');
  final heightController = TextEditingController(text: '170');
  final weightController = TextEditingController(text: '70');
  String selectedGender = 'No especificado';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> saveProfile() async {
    // Verificar que los valores son válidos y usar valores predeterminados si no lo son
    int age = int.tryParse(ageController.text) ?? 25;
    double height = double.tryParse(heightController.text) ?? 170.0;
    double weight = double.tryParse(weightController.text) ?? 70.0;

    // Crear objeto de perfil desde los controladores
    final profile = UserProfile(
      name: nameController.text,
      age: age,
      height: height,
      weight: weight,
      gender: selectedGender,
    );

    // Guardar usando el servicio
    await ProfileService.saveProfile(profile);
  }

  Future<void> loadProfile() async {
    final profile = await ProfileService.loadProfile();

    setState(() {
      nameController.text = profile.name;
      ageController.text = profile.age.toString();
      heightController.text = profile.height.toString();
      weightController.text = profile.weight.toString();
      selectedGender = profile.gender;
    });
  }

  // Método de ejemplo para usar el modelo de ML (preparado para implementación futura)
  Future<void> runModelPrediction() async {
    // Construir el perfil desde los datos actuales
    final profile = UserProfile(
      name: nameController.text,
      age: int.tryParse(ageController.text) ?? 25,
      height: double.tryParse(heightController.text) ?? 170.0,
      weight: double.tryParse(weightController.text) ?? 70.0,
      gender: selectedGender,
    );

    // Esta línea funcionará sin errores incluso sin TensorFlow implementado
    final result = await MLService.runInference(profile);

    print('Resultado del modelo (simulado por ahora): $result');

    // Ejemplo: mostrar un mensaje con los datos que se enviarían al modelo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Datos listos para ML: Edad=${profile.age}, Altura=${profile.height}, Peso=${profile.weight}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          const Background(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF732A85),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 23),
                          TextFormField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Edad',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 23),
                          DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Género',
                              prefixIcon: Icon(Icons.wc),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: 'Masculino',
                                child: Text(
                                  'Masculino',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Femenino',
                                child: Text(
                                  'Femenino',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'No binario',
                                child: Text(
                                  'No binario',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'No especificado',
                                child: Text(
                                  'No especificado',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                            selectedItemBuilder:
                                (context) => [
                                  const Text(
                                    'Masculino',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const Text(
                                    'Femenino',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const Text(
                                    'No binario',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const Text(
                                    'No especificado',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedGender = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 23),
                          TextFormField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              prefixIcon: Icon(Icons.monitor_weight),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 23),
                          TextFormField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Altura (cm)',
                              prefixIcon: Icon(Icons.height),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            22,
                            67,
                            144,
                          ).withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await saveProfile();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Perfil actualizado correctamente',
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            80,
                            29,
                            111,
                          ).withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Página para registrar la presión arterial
class BloodPressurePage extends StatefulWidget {
  const BloodPressurePage({super.key});

  @override
  State<BloodPressurePage> createState() => _BloodPressurePageState();
}

class _BloodPressurePageState extends State<BloodPressurePage> {
  List<Map<String, int>> pressures = List.generate(
    30,
    (_) => {'sys': 0, 'dia': 0},
  );
  final List<TextEditingController> sysControllers = List.generate(
    30,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> diaControllers = List.generate(
    30,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    loadPressures();
  }

  Future<void> loadPressures() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('blood_pressures');
    if (data != null) {
      final decoded = List<Map<String, dynamic>>.from(jsonDecode(data));
      setState(() {
        pressures =
            decoded
                .map(
                  (e) => {
                    'sys':
                        (e['sys'] is int)
                            ? e['sys'] as int
                            : int.tryParse(e['sys'].toString()) ?? 0,
                    'dia':
                        (e['dia'] is int)
                            ? e['dia'] as int
                            : int.tryParse(e['dia'].toString()) ?? 0,
                  },
                )
                .toList();
        for (int i = 0; i < 30; i++) {
          sysControllers[i].text =
              pressures[i]['sys'] == 0 ? '' : pressures[i]['sys'].toString();
          diaControllers[i].text =
              pressures[i]['dia'] == 0 ? '' : pressures[i]['dia'].toString();
        }
      });
    }
  }

  Future<void> savePressures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('blood_pressures', jsonEncode(pressures));
  }

  double get avgSys =>
      pressures.where((e) => e['sys']! > 0).isNotEmpty
          ? pressures
                  .where((e) => e['sys']! > 0)
                  .map((e) => e['sys']!)
                  .reduce((a, b) => a + b) /
              pressures.where((e) => e['sys']! > 0).length
          : 0;
  double get avgDia =>
      pressures.where((e) => e['dia']! > 0).isNotEmpty
          ? pressures
                  .where((e) => e['dia']! > 0)
                  .map((e) => e['dia']!)
                  .reduce((a, b) => a + b) /
              pressures.where((e) => e['dia']! > 0).length
          : 0;

  @override
  void dispose() {
    for (final c in sysControllers) {
      c.dispose();
    }
    for (final c in diaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presión arterial'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          const Background(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Registra tu presión arterial diaria (30 días)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade900,
                      ),
                      columns: const [
                        DataColumn(label: Text('Día')),
                        DataColumn(label: Text('Sistólica')),
                        DataColumn(label: Text('Diastólica')),
                      ],
                      rows: List.generate(30, (i) {
                        return DataRow(
                          cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(
                              SizedBox(
                                width: 70,
                                child: TextField(
                                  controller: sysControllers[i],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '--',
                                  ),
                                  onChanged: (v) {
                                    pressures[i]['sys'] = int.tryParse(v) ?? 0;
                                    savePressures();
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 70,
                                child: TextField(
                                  controller: diaControllers[i],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '--',
                                  ),
                                  onChanged: (v) {
                                    pressures[i]['dia'] = int.tryParse(v) ?? 0;
                                    savePressures();
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Promedio Sistólica: ${avgSys.toStringAsFixed(1)} mmHg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Promedio Diastólica: ${avgDia.toStringAsFixed(1)} mmHg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Página para mostrar el IMC
class IMCPage extends StatelessWidget {
  const IMCPage({super.key});

  double calcularIMC(double peso, double alturaCm) {
    final alturaM = alturaCm / 100.0;
    if (alturaM == 0) return 0;
    return peso / (alturaM * alturaM);
  }

  String clasificacionIMC(double imc) {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Future<UserProfile> getProfile() async {
    return await ProfileService.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMC'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          const Background(),
          FutureBuilder<UserProfile>(
            future: getProfile(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final profile = snapshot.data!;
              final imc = calcularIMC(profile.weight, profile.height);
              final clasif = clasificacionIMC(imc);
              return Center(
                child: Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tu IMC es:',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          imc.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Clasificación: $clasif',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Peso: ${profile.weight} kg\nAltura: ${profile.height} cm',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
