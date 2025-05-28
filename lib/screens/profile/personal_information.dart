import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePersonalInfoScreen extends StatefulWidget {
  final Map<String, String>? initialData;

  // ignore: use_super_parameters
  const UpdatePersonalInfoScreen({Key? key, this.initialData})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _UpdatePersonalInfoScreenState createState() =>
      _UpdatePersonalInfoScreenState();
}

class _UpdatePersonalInfoScreenState extends State<UpdatePersonalInfoScreen> {
  // Controllers for all fields
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.initialData != null) {
      // If data is passed directly
      setState(() {
        _surnameController.text = widget.initialData!['surname'] ?? '';
        _firstNameController.text = widget.initialData!['firstName'] ?? '';
        _dobController.text = widget.initialData!['dob'] ?? '';
        _phoneController.text = widget.initialData!['phone'] ?? '';
        _emailController.text = widget.initialData!['email'] ?? '';
        // Ensure consistent capitalization when loading
        _genderController.text =
            _capitalize(widget.initialData!['gender'] ?? '');
        _addressController.text = widget.initialData!['address'] ?? '';
        // Ensure consistent capitalization for selected value
        _selectedGender = _capitalize(widget.initialData!['gender'] ?? '');
      });
    } else {
      // Load from SharedPreferences if no data is passed
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _surnameController.text = prefs.getString('surname') ?? '';
        _firstNameController.text = prefs.getString('firstName') ?? '';
        _dobController.text = prefs.getString('dob') ?? '';
        _phoneController.text = prefs.getString('userPhone') ?? '';
        _emailController.text = prefs.getString('email') ?? '';
        // Ensure consistent capitalization when loading
        _genderController.text = _capitalize(prefs.getString('gender') ?? '');
        _addressController.text = prefs.getString('address') ?? '';
        // Ensure consistent capitalization for selected value
        _selectedGender = _capitalize(prefs.getString('gender') ?? '');
      });
    }
  }

  // Helper function to capitalize the first letter
  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Basic Personal Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Surname', _surnameController.text, context),
                  _buildInfoRow(
                      'First Name', _firstNameController.text, context),
                  _buildInfoRow('Date of Birth', _dobController.text, context),
                  _buildInfoRow('Address', _addressController.text, context),
                  _buildInfoRow('Phone Number', _phoneController.text, context),
                  _buildInfoRow(
                      'Email Address', _emailController.text, context),
                  _buildGenderRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.black87)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () {
              _showEditDialog(context, label);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderRow(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gender',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedGender ?? 'Not specified',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () {
              _showGenderDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String label) {
    TextEditingController controller;
    Widget? customWidget;

    switch (label) {
      case 'Surname':
        controller = _surnameController;
        break;
      case 'First Name':
        controller = _firstNameController;
        break;
      case 'Date of Birth':
        controller = _dobController;
        customWidget = TextButton(
          child: const Text('Select Date'),
          onPressed: () => _selectDate(context, controller),
        );
        break;
      case 'Address':
        controller = _addressController;
        break;
      case 'Phone Number':
        controller = _phoneController;
        break;
      case 'Email Address':
        controller = _emailController;
        break;
      default:
        controller = TextEditingController();
    }

    // Set the initial text in the dialog's text field
    controller.text = _getFieldController(label).text;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (customWidget != null) customWidget,
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveField(label, controller.text);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label updated successfully')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showGenderDialog(BuildContext context) {
    String? tempGender = _selectedGender; // Use the currently selected gender

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Gender'),
          content: SizedBox(
            width: double.minPositive,
            child: DropdownButtonFormField<String>(
              value: tempGender, // Use the temporary gender value
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              onChanged: (value) {
                // Update the temporary gender value when changed
                tempGender = value;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempGender != null) {
                  setState(() {
                    _selectedGender = tempGender;
                    _genderController.text = tempGender!;
                  });
                  _saveField('Gender', tempGender!);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Gender updated successfully')),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveField(String field, String value) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      switch (field) {
        case 'Surname':
          _surnameController.text = value;
          prefs.setString('surname', value);
          break;
        case 'First Name':
          _firstNameController.text = value;
          prefs.setString('firstName', value);
          break;
        case 'Date of Birth':
          _dobController.text = value;
          prefs.setString('dob', value);
          break;
        case 'Address':
          _addressController.text = value;
          prefs.setString('address', value);
          break;
        case 'Phone Number':
          _phoneController.text = value;
          prefs.setString('userPhone', value);
          break;
        case 'Email Address':
          _emailController.text = value;
          prefs.setString('email', value);
          break;
        case 'Gender':
          _genderController.text = value;
          _selectedGender = value;
          prefs.setString('gender', value);
          break;
      }
    });
  }

  TextEditingController _getFieldController(String label) {
    switch (label) {
      case 'Surname':
        return _surnameController;
      case 'First Name':
        return _firstNameController;
      case 'Date of Birth':
        return _dobController;
      case 'Address':
        return _addressController;
      case 'Phone Number':
        return _phoneController;
      case 'Email Address':
        return _emailController;
      case 'Gender':
        return _genderController;
      default:
        return TextEditingController();
    }
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
