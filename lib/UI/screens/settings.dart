import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
    return Stack(
      children: [
        // Fondo degradado principal
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD4B2F8), // Morado muy claro
                Color(0xFF5D7CEA), // Azul oscuro
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Neblina suave - efectos de ondas visuales
        Positioned(
          top: 100,
          left: -80,
          child: SoftWave(color: const Color(0xFFA01AA2).withOpacity(0.05)),
        ),
        Positioned(
          bottom: 0,
          right: -60,
          child: SoftWave(color: const Color(0xFF312290).withOpacity(0.03)),
        ),
        // Destellos sutiles simulando estrellas
        ...buildStars(30),
      ],
    );
  }

  List<Widget> buildStars(int count) {
    final random = Random();
    return List.generate(count, (index) {
      return Positioned(
        top: random.nextDouble() * 800,
        left: random.nextDouble() * 400,
        child: Container(
          width: 2,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2 + random.nextDouble() * 0.3),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
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
class SettingsTitle extends StatelessWidget {
  const SettingsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF732A85),
          ),
          textAlign: TextAlign.center,
        ),
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
        const SettingsTitle(),
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
        leading: Icon(icon, color: Colors.purpleAccent),
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
        backgroundColor: const Color(0xFFAA5ED9).withOpacity(0.6),
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

// Página de Preguntas Frecuentes
class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        backgroundColor: const Color(0xFFAA5ED9).withOpacity(0.6),
      ),
      body: Stack(
        children: [
          const Background(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                FAQItem(
                  icon: Icons.track_changes,
                  question:
                      '¿Cómo puedo realizar un seguimiento de mi progreso?',
                  answer:
                      'En la sección Seguimiento, puedes ver tu progreso diario y semanal. Asegúrate de registrar tus actividades regularmente para obtener estadísticas precisas.',
                ),
                FAQItem(
                  icon: Icons.bar_chart,
                  question:
                      '¿Cómo se calculan las estadísticas en la aplicación?',
                  answer:
                      'Las estadísticas se calculan en base a los datos que recopilamos a través de Health Connect. Esto incluye tus horas de sueño, fases y otros parámetros relevantes.',
                ),
                FAQItem(
                  icon: Icons.person,
                  question: '¿Cómo puedo actualizar mi perfil?',
                  answer:
                      'Para actualizar tu perfil, ve a Configuraciones > Mi Perfil. Aquí puedes cambiar tu nombre, género, edad y otros datos personales.',
                ),
                FAQItem(
                  icon: Icons.support_agent,
                  question: '¿Cómo puedo contactar al soporte técnico?',
                  answer:
                      'Puedes contactar al soporte técnico enviando un correo a soporte@yoho-health.com.',
                ),
                FAQItem(
                  icon: Icons.privacy_tip,
                  question:
                      '¿Dónde puedo encontrar las políticas de privacidad?',
                  answer:
                      'Las políticas de privacidad están disponibles en Configuración > Políticas de Privacidad. Aquí puedes leer sobre cómo manejamos tus datos y protegemos tu privacidad.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Elemento de pregunta frecuente
class FAQItem extends StatelessWidget {
  final IconData icon;
  final String question;
  final String answer;

  const FAQItem({
    super.key,
    required this.icon,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF732A85), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      color: Color(0xFF6F1B6E),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              answer,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
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
        backgroundColor: const Color(0xFFAA5ED9).withOpacity(0.6),
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
                  activeColor: const Color(0xFF732A85),
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
                  trailing: const Icon(
                    Icons.brightness_4,
                    color: Color(0xFF732A85),
                  ),
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
                  trailing: const Icon(
                    Icons.language,
                    color: Color(0xFF732A85),
                  ),
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
                  trailing: const Icon(Icons.restore, color: Color(0xFF732A85)),
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

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController(text: 'Usuario');
  final ageController = TextEditingController(text: '25');
  String selectedGender = 'No especificado';

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFFAA5ED9).withOpacity(0.6),
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
                    color: Colors.white.withOpacity(0.9),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Edad',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Género',
                              prefixIcon: Icon(Icons.wc),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Masculino',
                                child: Text('Masculino'),
                              ),
                              DropdownMenuItem(
                                value: 'Femenino',
                                child: Text('Femenino'),
                              ),
                              DropdownMenuItem(
                                value: 'No binario',
                                child: Text('No binario'),
                              ),
                              DropdownMenuItem(
                                value: 'No especificado',
                                child: Text('No especificado'),
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
                          backgroundColor: Colors.blueAccent.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Aquí iría la lógica para guardar el perfil
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Perfil actualizado correctamente'),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFAA5ED9,
                          ).withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Guardar'),
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
