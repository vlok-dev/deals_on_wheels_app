import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_navigation_screen.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return MainNavigationScreen();
        } else {
          return AuthScreen();
        }
      },
    );
  }
}
