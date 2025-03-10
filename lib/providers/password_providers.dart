import 'package:flutter/material.dart';

class PasswordProvider extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  void validatePasswords() {
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;
    
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      debugPrint("Fields cannot be empty");
      return;
    }
    if (newPassword != confirmPassword) {
      debugPrint("Passwords do not match");
      return;
    }
    debugPrint("Password successfully changed");
  }
}
