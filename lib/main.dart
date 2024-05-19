import 'dart:async';
import 'package:cgk/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://eughueucuzinthtorkyt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1Z2h1ZXVjdXppbnRodG9ya3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDA0ODQ2NDcsImV4cCI6MjAxNjA2MDY0N30.1IXKCtjMpNB0DJ2_ZBixn59MSr7mlxVeebTSYHjzlFY',
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  isRemembered();
  runApp(const MyApp());
}

Future<void> isRemembered() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  isLogin = prefs.getBool("isLogin") ?? false;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isLogin ? const menu() : const LoginScreen(),
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionHandleColor: Colors.white,
        ),
      ),
    );
  }
}

