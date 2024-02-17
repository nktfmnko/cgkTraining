import 'package:cgk/profile.dart';
import 'package:cgk/select_questions.dart';
import 'package:cgk/timer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'statistics.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://eughueucuzinthtorkyt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1Z2h1ZXVjdXppbnRodG9ya3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDA0ODQ2NDcsImV4cCI6MjAxNjA2MDY0N30.1IXKCtjMpNB0DJ2_ZBixn59MSr7mlxVeebTSYHjzlFY',
  );
  //Раскомментировать, и написать название виджета, который вы вызываете
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(routes: {
      '/': (context) => const SelectQuestion(),
      '/statistic': (context) => const stat(),
      '/timer': (context) => const StateTimerPage(),
      '/profile': (context) => profile()
    });
  }
}
