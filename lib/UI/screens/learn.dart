import 'package:flutter/material.dart';
import 'dart:math';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: const [Background(), HomeBodyTips()]),
    );
  }
}

class HomeBodyTips extends StatelessWidget {
  const HomeBodyTips({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(children: [TitleSection(), CardTable()]),
    );
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

// Título e introducción
class TitleSection extends StatelessWidget {
  const TitleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[900]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.nights_stay, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(
              'Secretos para un Buen Descanso',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Descubre recomendaciones prácticas y sencillas que te ayudarán a mejorar la calidad de tu sueño noche tras noche.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}

// Cards con consejos de sueño
class CardTable extends StatelessWidget {
  const CardTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      children: const [
        TableRow(
          children: [
            TipCard(
              imagen: 'assets/Horas_sueno.jpg',
              color: Colors.white,
              titulo: 'Mantener un horario de sueño regular',
              detalle:
                  'Una programación consistente de la hora de acostarse y de despertarse favorece la sincronización del ritmo circadiano, reduciendo la latencia para dormir y mejorando la eficiencia del sueño. Estudios epidemiológicos y de revisión muestran asociaciones claras entre la regularidad horaria y mejores indicadores subjetivos y objetivos del sueño.',
            ),
          ],
        ),
        TableRow(
          children: [
            TipCard(
              imagen: 'assets/Ambiente_descanso.jpg',
              color: Colors.white,
              titulo: 'Optimizar el ambiente de descanso',
              detalle:
                  'Un entorno oscuro, silencioso y con temperatura agradable facilita la continuidad del sueño y reduce los despertares nocturnos. Revisiones muestran que el control de ruido y luz, así como el confort del colchón y la almohada, se asocian con mejoría en la calidad percibida del sueño.',
            ),
          ],
        ),
        TableRow(
          children: [
            TipCard(
              imagen: 'assets/Evitar_estimulos.jpg',
              color: Colors.white,
              titulo:
                  'Evitar estimulantes, alcohol y comidas pesadas antes de dormir',
              detalle:
                  'La ingesta de cafeína, nicotina o alcohol en las horas previas al descanso, así como cenas copiosas, prolongan la latencia de inicio del sueño y disminuyen su calidad. La evidencia de ensayos clínicos respalda la recomendación de abstenerse de estos componentes al menos 3–4 horas antes de acostarse.',
            ),
          ],
        ),
        TableRow(
          children: [
            TipCard(
              imagen: 'assets/Libre_pantallas.jpg',
              color: Colors.white,
              titulo: 'Establecer una rutina relajante libre de pantallas',
              detalle:
                  'Realizar actividades tranquilas (lectura ligera, meditación, técnicas de relajación) y evitar la exposición a dispositivos electrónicos 30–60 min antes de dormir mejora la facilidad de conciliación y reduce la estimulación cortical. Revisiones apuntan al impacto negativo de la luz azul y recomiendan una transición gradual a un estado de reposo.',
            ),
          ],
        ),
        TableRow(
          children: [
            TipCard(
              imagen: 'assets/Hacer_actividadF.png',
              color: Colors.white,
              titulo: 'Incorporar actividad física regular',
              detalle:
                  'El ejercicio, especialmente el entrenamiento de resistencia, es una intervención eficaz para mejorar la calidad del sueño, siempre que no se realice en la ventana de 1–2 horas previas a la hora de acostarse. Un metaanálisis en red sitúa al entrenamiento de resistencia como la estrategia más beneficiosa en adultos no ancianos.',
            ),
          ],
        ),
      ],
    );
  }
}

// Tarjeta individual para cada tip
class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.imagen,
    required this.color,
    required this.titulo,
    required this.detalle,
  });

  final String imagen;
  final Color color;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TipDetailPage(titulo: titulo, detalle: detalle),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(15),
        height: 190,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[900]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: 300,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(imagen),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(
              titulo,
              style: TextStyle(color: color, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Página de detalle del tip
class TipDetailPage extends StatelessWidget {
  final String titulo;
  final String detalle;

  const TipDetailPage({super.key, required this.titulo, required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Tip'),
        backgroundColor: (Colors.grey[900]!),
      ),
      body: Stack(
        children: [
          const Background(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF260226).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Text(
                    detalle,
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                    textAlign: TextAlign.justify,
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
