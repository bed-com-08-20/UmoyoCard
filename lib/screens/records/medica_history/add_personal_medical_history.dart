import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddPersonalMedicalRecordScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const AddPersonalMedicalRecordScreen({Key? key}) : super(key: key);

  @override
  State<AddPersonalMedicalRecordScreen> createState() =>
      _AddPersonalMedicalRecordScreenState();
}

class _AddPersonalMedicalRecordScreenState
    extends State<AddPersonalMedicalRecordScreen> {
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
    'Hospitalization': [
      'Admission Date',
      'Discharge Date',
      'Reason for Hospitalization',
      'Hospital Name',
      'Treatments Received',
      'Complications (if any)'
    ],
    'Immunization': [
      'Vaccine Name',
      'Date Administered',
      'Location/Clinic Name',
      'Next Due Date (if applicable)',
      'Adverse Reactions (if any)'
    ],
    'Mental Health': [
      'Diagnosis',
      'Date Diagnosed',
      'Symptoms',
      'Treatments/Therapies',
      'Medications',
      'Hospitalizations (if any)'
    ],
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

  // Save record in SharedPreferences
  void _saveRecord() async {
    final Map<String, dynamic> newRecord = {
      'title': selectedCategory,
      'details': {
        for (var field in categoryFields[selectedCategory]!)
          field: controllers[field]?.text ?? '',
      },
    };

    // Get SharedPreferences instance and save the record
    final prefs = await SharedPreferences.getInstance();
    final String key = 'medical_records';
    final List<String> storedRecords = prefs.getStringList(key) ?? [];

    // Convert the new record to JSON and add it to the list
    storedRecords.add(jsonEncode(newRecord)); // Store as JSON

    // Save the updated list of records
    await prefs.setStringList(key, storedRecords);

    // Close the screen and return the new record to the previous screen
    // ignore: use_build_context_synchronously
    Navigator.pop(context, newRecord);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Personal Medical Record',
          style: TextStyle(color: Colors.blue),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveRecord,
                    icon: const Icon(Icons.check),
                    label: const Text('Save Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black),
                    label: const Text('Cancel',
                        style: TextStyle(color: Colors.black)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                ],
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
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      );
    }).toList();
  }
}
