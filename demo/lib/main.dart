import 'package:flutter/material.dart';

import 'pages/gradient_page.dart';
import 'pages/home_page.dart';
import 'pages/quiz_page.dart';

void main() => runApp(const ChromaticDemoApp());

class ChromaticDemoApp extends StatelessWidget {
  const ChromaticDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'chromatic — color science for Dart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/gradient': (_) => const GradientPage(),
        '/quiz': (_) => const QuizPage(),
      },
    );
  }
}
