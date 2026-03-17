import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'screens/auth_gate.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://whxumobtcmfrellnmkgm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndoeHVtb2J0Y21mcmVsbG5ta2dtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2NjE3MDcsImV4cCI6MjA4OTIzNzcwN30.CbunNp8ulPqbBXxZpZVjwy10BVrXUowXuXyZfRyCIn0',
  );
  runApp(const DealsOnWheelsApp());
}

class DealsOnWheelsApp extends StatelessWidget {
  const DealsOnWheelsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Deals & Savings Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthGate(),
    );
  }
}
