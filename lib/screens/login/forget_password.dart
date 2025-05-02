import 'package:flutter/material.dart';
import 'package:umoyocard/screens/login/new_password.dart';


class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailPhoneController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reset Password",
          style: TextStyle(color: Colors.blue, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your email or phone number to receive a reset link.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: emailPhoneController,
              hintText: "Email",
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Send Reset Link",
              onPressed: () {
                print("Reset link sent to: ${emailPhoneController.text}");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewPasswordScreen()),
                );
              },
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

