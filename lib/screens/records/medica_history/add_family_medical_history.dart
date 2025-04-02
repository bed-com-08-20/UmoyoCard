// lib/screens/records/medica_history/add_family_medical_history.dart
import 'package:flutter/material.dart';

class AddFamilyMedicalHistoryScreen extends StatefulWidget {
  const AddFamilyMedicalHistoryScreen({Key? key}) : super(key: key);

  @override
  _AddFamilyMedicalHistoryScreenState createState() =>
      _AddFamilyMedicalHistoryScreenState();
}

class _AddFamilyMedicalHistoryScreenState
    extends State<AddFamilyMedicalHistoryScreen> {
  String selectedCategory = 'Chronic Illness';
  final Map<String, List<String>> categoryFields = {
    'Chronic Illness': [
      'Condition Name',
      'Date Diagnosed',
      'Status',
      'Medications'
    ],
    'Allergies': [
      'Allergen Name',
      'Reaction Type',
      'Last Occurrence Date',
      'Treatment Used'
    ],
    'Surgery': ['Date Performed', 'Hospital Name', 'Complications (if any)'],
    // Add more categories as needed
  };

  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var fields in categoryFields.values) {
      for (var field in fields) {
        controllers[field] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveRecord() {
    // Save logic similar to your personal medical history screen
    final newRecord = {
      'title': selectedCategory,
      'details': {
        for (var field in categoryFields[selectedCategory]!)
          field: controllers[field]?.text ?? '',
      },
    };

    // Add saving logic (e.g., using SharedPreferences or any other method)
    Navigator.pop(context, newRecord); // Return the new record to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Medical History'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Select Category'),
                items: categoryFields.keys.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ..._buildDynamicFields(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveRecord,
                child: const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    return categoryFields[selectedCategory]!.map((field) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controllers[field],
          decoration: InputDecoration(
            labelText: field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      );
    }).toList();
  }
}
