import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'deals_feed_screen.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return child;
    } else {
      return AuthScreen();
    }
  }
}
