import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'deals_feed_screen.dart';
import 'city_selector.dart';
import '../services/user_profile_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final List<String> _cities = ['Port Elizabeth', 'Cape Town', 'Johannesburg'];
  String? _selectedCity;
  bool _showSignUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _signInOrSignUp({required bool isSignUp}) async {
    if (isSignUp && _selectedCity == null) {
      setState(() {
        _error = 'Please select your city.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (isSignUp) {
        final response = await auth.signUp(email: email, password: password);
        if (response.user != null) {
          // Save city to profile
          await UserProfileService.setCity(response.user!.id, _selectedCity!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign up successful! Please check your email to confirm.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DealsFeedScreen()),
          );
        }
      } else {
        final response = await auth.signInWithPassword(email: email, password: password);
        if (response.user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DealsFeedScreen()),
          );
        } else {
          setState(() {
            _error = 'Invalid login details';
          });
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_showSignUp ? 'Create Account' : 'Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_showSignUp) ...[
              SizedBox(height: 12),
              CitySelector(
                cities: _cities,
                selectedCity: _selectedCity,
                onChanged: (city) => setState(() => _selectedCity = city),
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 16),
            if (_isLoading)
              CircularProgressIndicator()
            else ...[
              if (!_showSignUp)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _signInOrSignUp(isSignUp: false),
                      child: Text('Login'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _showSignUp = true;
                        _error = null;
                      }),
                      child: Text('Create an account'),
                    ),
                  ],
                ),
              if (_showSignUp)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _signInOrSignUp(isSignUp: true),
                      child: Text('Sign Up'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _showSignUp = false;
                        _error = null;
                      }),
                      child: Text('Back to login'),
                    ),
                  ],
                ),
            ]
          ],
        ),
      ),
    );
  }
}
