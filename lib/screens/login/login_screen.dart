import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/home/home_screen.dart';
import 'package:umoyocard/screens/login/create_account.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void handleLogin() async {
    String emailOrPhone = _emailOrPhoneController.text.trim();
    String password = _passwordController.text.trim();

    if (emailOrPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Email or Phone')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email');
    final storedPhone = prefs.getString('phone');
    final storedPassword = prefs.getString('password');

    if ((emailOrPhone == storedEmail || emailOrPhone == storedPhone) &&
        password == storedPassword) {
      // Store login times
      final currentLogin = DateTime.now().toString();
      final previousLogin = prefs.getString('lastLogin');

      await prefs.setString('lastLogin', currentLogin);
      if (previousLogin != null) {
        await prefs.setString('previousLogin', previousLogin);
      }
      await prefs.setBool('isLoggedIn', true);

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials! Please try again.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to UmoyoCard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Securely access your health passport.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32.0),
              TextField(
                controller: _emailOrPhoneController,
                decoration: InputDecoration(
                  labelText: 'Phone number or Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Forgot Password Screen not yet implemented!')),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 16.0, color: Colors.green),
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading ? null : handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateAccount()),
                      );
                    },
                    child: const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16.0, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
