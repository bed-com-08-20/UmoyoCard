import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validateNewPassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _getNewPasswordError(String password) {
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

  void _validateNewPassword() {
    final password = _newPasswordController.text.trim();
    setState(() {
      _newPasswordError =
          password.isEmpty ? null : _getNewPasswordError(password);
    });
  }

  void _validateConfirmPassword() {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    setState(() {
      _confirmPasswordError = confirmPassword.isEmpty
          ? null
          : (newPassword != confirmPassword ? "Passwords do not match" : null);
    });
  }

  Future<void> _savePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty) {
      setState(() {
        _oldPasswordError = "Please enter your current password";
      });
      return;
    }

    if (newPassword.isEmpty) {
      setState(() {
        _newPasswordError = "Please enter a new password";
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = "Please confirm your new password";
      });
      return;
    }

    // Validate passwords
    _validateNewPassword();
    _validateConfirmPassword();

    if (_newPasswordError != null || _confirmPasswordError != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('password');

    // Verify old password
    if (savedPassword != oldPassword) {
      setState(() {
        _oldPasswordError = "Incorrect current password";
      });
      return;
    }

    // Save new password
    await prefs.setString('password', newPassword);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully!')),
    );

    // Clear fields
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    // Navigate back to previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current password and set a new password',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Current Password Field
            _buildPasswordField(
              'Current Password',
              _oldPasswordController,
              _isOldPasswordVisible,
              (value) {
                setState(() {
                  _isOldPasswordVisible = value;
                });
              },
              errorText: _oldPasswordError,
            ),

            const SizedBox(height: 16),

            // New Password Field
            _buildPasswordField(
              'New Password',
              _newPasswordController,
              _isNewPasswordVisible,
              (value) {
                setState(() {
                  _isNewPasswordVisible = value;
                });
              },
              errorText: _newPasswordError,
            ),

            const SizedBox(height: 16),

            // Confirm Password Field
            _buildPasswordField(
              'Confirm New Password',
              _confirmPasswordController,
              _isConfirmPasswordVisible,
              (value) {
                setState(() {
                  _isConfirmPasswordVisible = value;
                });
              },
              errorText: _confirmPasswordError,
            ),

            const SizedBox(height: 32),

            // Save Password Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _savePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Password',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    bool isVisible,
    Function(bool) onVisibilityChanged, {
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        errorText: errorText,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            onVisibilityChanged(!isVisible);
          },
        ),
      ),
    );
  }
}
