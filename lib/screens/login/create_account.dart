import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              CreateAccountForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateAccountForm extends StatefulWidget {
  @override
  _CreateAccountFormState createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  final Map<String, String?> _errorMessages = {};

  Future<void> _saveToFirebase() async {
    bool isValid = true;

    setState(() {
      _errorMessages.clear();
      if (_fullnameController.text.isEmpty) {
        _errorMessages['fullname'] = "This field is required";
        isValid = false;
      }
      if (_dobController.text.isEmpty) {
        _errorMessages['dob'] = "This field is required";
        isValid = false;
      }
      if (_addressController.text.isEmpty) {
        _errorMessages['address'] = "This field is required";
        isValid = false;
      }
      if (_phoneController.text.isEmpty) {
        _errorMessages['phone'] = "This field is required";
        isValid = false;
      }
      if (_emailController.text.isEmpty) {
        _errorMessages['email'] = "This field is required";
        isValid = false;
      }
      if (_nationalIdController.text.isEmpty) {
        _errorMessages['national_id'] = "This field is required";
        isValid = false;
      }
      if (_nationalityController.text.isEmpty) {
        _errorMessages['nationality'] = "This field is required";
        isValid = false;
      }
      if (_genderController.text.isEmpty) {
        _errorMessages['gender'] = "This field is required";
        isValid = false;
      }
    });

    if (isValid) {
      try {
        await FirebaseFirestore.instance.collection('users').add({
          'fullname': _fullnameController.text,
          'dob': _dobController.text,
          'address': _addressController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'national_id': _nationalIdController.text,
          'nationality': _nationalityController.text,
          'gender': _genderController.text,
          'created_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully! 🎉")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreatePassword()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          FormTextField(
            label: "Fullname",
            controller: _fullnameController,
            errorText: _errorMessages['fullname'],
            onChanged: (value) =>
                setState(() => _errorMessages['fullname'] = null),
          ),
          FormTextField(
            label: "Date of Birth",
            controller: _dobController,
            errorText: _errorMessages['dob'],
            onChanged: (value) => setState(() => _errorMessages['dob'] = null),
          ),
          FormTextField(
            label: "Address",
            controller: _addressController,
            errorText: _errorMessages['address'],
            onChanged: (value) =>
                setState(() => _errorMessages['address'] = null),
          ),
          FormTextField(
            label: "Phone Number",
            controller: _phoneController,
            errorText: _errorMessages['phone'],
            onChanged: (value) =>
                setState(() => _errorMessages['phone'] = null),
          ),
          FormTextField(
            label: "Email Address",
            controller: _emailController,
            errorText: _errorMessages['email'],
            onChanged: (value) =>
                setState(() => _errorMessages['email'] = null),
          ),
          FormTextField(
            label: "National ID",
            controller: _nationalIdController,
            errorText: _errorMessages['national_id'],
            onChanged: (value) =>
                setState(() => _errorMessages['national_id'] = null),
          ),
          FormTextField(
            label: "Nationality",
            controller: _nationalityController,
            errorText: _errorMessages['nationality'],
            onChanged: (value) =>
                setState(() => _errorMessages['nationality'] = null),
          ),
          FormTextField(
            label: "Gender",
            controller: _genderController,
            errorText: _errorMessages['gender'],
            onChanged: (value) =>
                setState(() => _errorMessages['gender'] = null),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveToFirebase,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueAccent,
            ),
            child: const Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class FormTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const FormTextField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          errorText: errorText,
        ),
      ),
    );
  }
}
