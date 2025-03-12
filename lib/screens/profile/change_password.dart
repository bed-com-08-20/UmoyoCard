import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _savePassword() {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New Password',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a new password to secure your account',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // New Password Field
            _buildPasswordField('New Password', _newPasswordController),

            const SizedBox(height: 16),

            // Confirm Password Field
            _buildPasswordField('Confirm Password', _confirmPasswordController),

            const SizedBox(height: 32),

            // Save Password Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _savePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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

  Widget _buildPasswordField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
