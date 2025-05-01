import 'package:flutter/material.dart';
import 'UI/screens/tracking.dart'; // Asegúrate que la ruta es correcta
import 'UI/screens/statistics.dart'; // Asegúrate que la ruta es correcta

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOHO Health Tracker', // Puedes cambiar el título
      theme: ThemeData(
        brightness: Brightness.dark, // Tema oscuro global
        primarySwatch: Colors.blue, // Un color primario base
        scaffoldBackgroundColor: Colors.black, // Fondo negro por defecto
        cardColor: Colors.grey[900], // Color de las tarjetas
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900], // Color de AppBar
          elevation: 0, // Sin sombra
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ), // Color de iconos en AppBar
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900], // Fondo de la barra de navegación
          selectedItemColor: Colors.white, // Color del ítem seleccionado
          unselectedItemColor:
              Colors.grey[600], // Color de ítems no seleccionados
          showUnselectedLabels:
              false, // Opcional: ocultar etiquetas no seleccionadas
          showSelectedLabels: true,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // Semilla para generar otros colores
          brightness: Brightness.dark, // Asegura que el esquema sea oscuro
          // background: Colors.black, // Eliminado: Ya cubierto por scaffoldBackgroundColor
          surface:
              Colors.grey[900], // Color de superficie (ej. tarjetas, appbar)
        ).copyWith(secondary: Colors.blueAccent), // Color secundario/acento
        useMaterial3: true, // Habilitar Material 3 si lo deseas
      ),
      debugShowCheckedModeBanner: false, // Ocultar banner de debug
      home: const HomeScreen(), // Iniciar con nuestra pantalla principal
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice de la pantalla actual

  // Lista de pantallas a mostrar
  static final List<Widget> _widgetOptions = <Widget>[
    // Corrección: 'const' eliminado
    TrackingScreen(),
    StatisticsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El AppBar se manejará dentro de cada pantalla si es necesario
      // appBar: AppBar(title: const Text('YOHO')), // O un AppBar global aquí
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart), // O un icono más específico
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), // O Icons.analytics
            label: 'Estadísticas',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
