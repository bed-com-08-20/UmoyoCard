import 'package:flutter/material.dart';
import 'package:umoyocard/screens/login/create_password.dart';

class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Create an Account"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
          children: [
            const Text(
              "Sign up to get started",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const CreateAccountForm(),
          ],
        ),
        ),
      ),
    );
  }
}

class CreateAccountForm extends StatelessWidget {
  const CreateAccountForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormTextField(label: "Fullname"),
        FormTextField(label: "Date of Birth"),
        FormTextField(label: "Address"),
        FormTextField(label: "Phone Number"),
        FormTextField(label: "Email Address"),
        FormTextField(label: "National ID"),
        FormTextField(label: "Nationality"),
        FormTextField(label: "Gender"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePassword()),
      );
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blueAccent),
          child: const Text("Next", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class FormTextField extends StatelessWidget {
  final String label;
  const FormTextField({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
