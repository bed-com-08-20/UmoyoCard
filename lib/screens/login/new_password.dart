import 'package:flutter/material.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void savePassword() {
    if (_formKey.currentState!.validate()) {
            
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create New Password",
          style: TextStyle(color: Colors.blue, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter a new password to secure your account",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: newPasswordController,
                hintText: "New Password",
                isPassword: true,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: confirmPasswordController,
                hintText: "Confirm Password",
                isPassword: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return "Passwords do not match!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Save Password",
                onPressed: savePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}
