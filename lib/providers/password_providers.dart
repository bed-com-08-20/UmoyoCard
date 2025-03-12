import 'package:flutter/material.dart';

class PasswordProvider extends ChangeNotifier {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  String? passwordError;
  String? confirmPasswordError;

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
    if (password.length < 6) return "Password must be at least 6 characters long";
    if (!password.contains(RegExp(r'[A-Z]'))) return "Password must contain at least one uppercase letter";
    if (!password.contains(RegExp(r'[0-9]'))) return "Password must contain at least one number";
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
      confirmPasswordError = _getConfirmPasswordError(password, confirmPassword);
    }

    notifyListeners();
  }

  Future<void> savePasswordToFirebase() async {
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

    if (passwordError == null && confirmPasswordError == null) {
      
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
