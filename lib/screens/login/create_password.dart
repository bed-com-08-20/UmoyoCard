import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umoyocard/providers/password_providers.dart';

class CreatePassword extends StatelessWidget {
  const CreatePassword({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PasswordProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Create a Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Create a password to secure your account. It should be something others can't guess."),
            const SizedBox(height: 20),
            PasswordTextField(
              controller: provider.passwordController,
              hintText: "Password",
              obscureText: true,
              errorText: provider.passwordError,
            ),
            const SizedBox(height: 16),
            PasswordTextField(
              controller: provider.confirmPasswordController,
              hintText: "Confirm Password",
              obscureText: true,
              errorText: provider.confirmPasswordError,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: "Save Password",
              onPressed: () async {
                await provider.savePasswordToSharedPrefs(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? errorText;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: errorText == null ? Colors.grey : Colors.red,
          ),
        ),
        errorText: errorText,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
