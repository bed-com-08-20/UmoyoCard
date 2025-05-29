import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:umoyocard/screens/login/create_password.dart';
import 'package:umoyocard/providers/password_providers.dart';

class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create an Account"),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Sign up to get started",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            CreateAccountForm(),
          ],
        ),
      ),
    );
  }
}

class CreateAccountForm extends StatefulWidget {
  const CreateAccountForm({super.key});

  @override
  State<CreateAccountForm> createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final Map<String, String?> _errorMessages = {};
  final Uuid _uuid = const Uuid();
  String? _selectedGender;

  String _formatDateForFHIR(String inputDate) {
    try {
      final parts = inputDate.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
    }
    return inputDate;
  }

  Future<void> _saveToSharedPrefs() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessages.clear());

    try {
      final prefs = await SharedPreferences.getInstance();

      // Generate FHIR-compatible patient ID
      final uuid = _uuid.v4();
      final userId =
          'pat-$uuid'; // This format should match the FHIR validation

      debugPrint('Generated patient ID: $userId');

      // Format date before saving
      final dob = _formatDateForFHIR(_dobController.text);

      // Combine surname and first name for full name
      final fullName =
          '${_surnameController.text} ${_firstNameController.text}';

      // Save all user data to SharedPreferences
      await Future.wait([
        prefs.setString('userId', userId),
        prefs.setString('userName', fullName),
        prefs.setString('surname', _surnameController.text),
        prefs.setString('firstName', _firstNameController.text),
        if (_phoneController.text.isNotEmpty)
          prefs.setString('userPhone', _phoneController.text),
        if (_emailController.text.isNotEmpty)
          prefs.setString('email', _emailController.text),
        prefs.setString('dob', dob),
        if (_selectedGender != null)
          prefs.setString('gender', _selectedGender!),
        prefs.setString('address', _addressController.text),
      ]);

      // Verify the ID was saved correctly
      final savedId = prefs.getString('userId');
      if (savedId == null || savedId.isEmpty) {
        throw Exception('Failed to save patient ID');
      }

      // Pass data to PasswordProvider
      final passwordProvider =
          Provider.of<PasswordProvider>(context, listen: false);
      passwordProvider.email = _emailController.text;
      passwordProvider.phone = _phoneController.text;
      passwordProvider.fullName = fullName;
      passwordProvider.userId =
          userId; // Pass the FHIR-compatible ID to PasswordProvider

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePassword()),
      );
    } catch (e) {
      debugPrint('Error saving account: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating account: ${e.toString()}")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _surnameController,
            decoration: InputDecoration(
              labelText: "Surname*",
              errorText: _errorMessages['surname'],
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? "Required field" : null,
            onChanged: (value) =>
                setState(() => _errorMessages['surname'] = null),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: "First Name*",
              errorText: _errorMessages['firstName'],
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? "Required field" : null,
            onChanged: (value) =>
                setState(() => _errorMessages['firstName'] = null),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            decoration: InputDecoration(
              labelText: "Date of Birth (DD/MM/YYYY)*",
              errorText: _errorMessages['dob'],
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            keyboardType: TextInputType.datetime,
            validator: (value) {
              if (value?.isEmpty ?? true) return "Required field";
              final parts = value!.split('/');
              if (parts.length != 3) return "Use DD/MM/YYYY format";
              try {
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                if (day < 1 || day > 31) return "Invalid day";
                if (month < 1 || month > 12) return "Invalid month";
                if (year < 1900 || year > DateTime.now().year)
                  return "Invalid year";
              } catch (e) {
                return "Use numbers only (DD/MM/YYYY)";
              }
              return null;
            },
            onChanged: (value) => setState(() => _errorMessages['dob'] = null),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: "Address*",
              errorText: _errorMessages['address'],
              border: const OutlineInputBorder(),
            ),
            // maxLines: 2,
            keyboardType: TextInputType.streetAddress,
            validator: (value) =>
                value?.isEmpty ?? true ? "Required field" : null,
            onChanged: (value) =>
                setState(() => _errorMessages['address'] = null),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: "Phone Number",
              errorText: _errorMessages['phone'],
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) =>
                setState(() => _errorMessages['phone'] = null),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email Address",
              errorText: _errorMessages['email'],
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) =>
                setState(() => _errorMessages['email'] = null),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: "Gender",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
                _genderController.text = value ?? '';
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveToSharedPrefs,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Continue",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _firstNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
