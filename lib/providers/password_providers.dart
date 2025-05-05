import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/login/login_screen.dart';

class PasswordProvider extends ChangeNotifier {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? passwordError;
  String? confirmPasswordError;
  String? email;
  String? phone;
  String? fullName;
  String? userId; // Will be passed from CreateAccountForm

  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  PasswordProvider() {
    passwordController.addListener(_validatePasswords);
    confirmPasswordController.addListener(_validatePasswords);
    passwordFocusNode.addListener(() {
      if (!passwordFocusNode.hasFocus) _validatePasswords();
    });
    confirmPasswordFocusNode.addListener(() {
      if (!confirmPasswordFocusNode.hasFocus) _validatePasswords();
    });
  }

  String? _getPasswordError(String password) {
    if (password.length < 6) {
      return "Password must be at least 6 characters long";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one uppercase letter";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number";
    }
    return null;
  }

  String? _getConfirmPasswordError(String password, String confirmPassword) {
    if (password != confirmPassword) return "Passwords do not match";
    return null;
  }

  void _validatePasswords() {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    passwordError = password.isEmpty ? null : _getPasswordError(password);
    confirmPasswordError = confirmPassword.isEmpty
        ? null
        : _getConfirmPasswordError(password, confirmPassword);

    notifyListeners();
  }

  Future<void> savePasswordToSharedPrefs(BuildContext context) async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

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

    _validatePasswords();
    if (passwordError != null || confirmPasswordError != null) return;

    final prefs = await SharedPreferences.getInstance();

    // Use the userId that was passed from CreateAccountForm
    if (userId == null || userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Missing user ID")),
      );
      return;
    }

    await Future.wait([
      prefs.setString('userId', userId!),
      prefs.setString('userName', fullName ?? ''),
      prefs.setString('email', email ?? ''),
      prefs.setString('phone', phone ?? ''),
      prefs.setString('password', password),
      prefs.setBool('isLoggedIn', true),
    ]);

    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
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
