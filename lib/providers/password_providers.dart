import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/home/home_screen.dart';

class PasswordProvider extends ChangeNotifier {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? passwordError;
  String? confirmPasswordError;
  String? email; // Will be passed from CreateAccountForm
  String? phone; // Will be passed from CreateAccountForm
  String? fullName; // Will be passed from CreateAccountForm

  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  PasswordProvider() {
    passwordController.addListener(() {
      _validatePasswords();
    });

    confirmPasswordController.addListener(() {
      _validatePasswords();
    });

    passwordFocusNode.addListener(() {
      if (!passwordFocusNode.hasFocus) {
        _validatePasswords();
      }
    });

    confirmPasswordFocusNode.addListener(() {
      if (!confirmPasswordFocusNode.hasFocus) {
        _validatePasswords();
      }
    });
  }

  String? _getPasswordError(String password) {
    if (password.length < 6)
      return "Password must be at least 6 characters long";
    if (!password.contains(RegExp(r'[A-Z]')))
      return "Password must contain at least one uppercase letter";
    if (!password.contains(RegExp(r'[0-9]')))
      return "Password must contain at least one number";
    return null;
  }

  String? _getConfirmPasswordError(String password, String confirmPassword) {
    if (password != confirmPassword) return "Passwords do not match";
    return null;
  }

  void _validatePasswords() {
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    passwordError = null;
    confirmPasswordError = null;

    if (password.isNotEmpty) {
      passwordError = _getPasswordError(password);
    }

    if (confirmPassword.isNotEmpty) {
      confirmPasswordError =
          _getConfirmPasswordError(password, confirmPassword);
    }

    notifyListeners();
  }

  Future<void> savePasswordToSharedPrefs(BuildContext context) async {
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty) {
      passwordError = "Password cannot be empty";
      notifyListeners();
      return;
    }
    if (confirmPassword.isEmpty) {
      confirmPasswordError = "Confirm Password cannot be empty";
      notifyListeners();
      return;
    }

    // Final validation
    _validatePasswords();

    if (passwordError == null && confirmPasswordError == null) {
      final prefs = await SharedPreferences.getInstance();

      // Generate a simple user ID (in a real app, use Firebase Auth UID)
      String userId = DateTime.now().millisecondsSinceEpoch.toString();

      // Save user credentials
      await prefs.setString('userId', userId);
      await prefs.setString('userName', fullName ?? '');
      await prefs.setString('email', email ?? '');
      await prefs.setString('phone', phone ?? '');
      await prefs.setString('password', password);
      await prefs.setBool('isLoggedIn', true);

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }
}
