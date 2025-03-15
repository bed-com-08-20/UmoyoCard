import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/records/medica_history/add_personal_medical_history.dart';
import 'dart:convert';

class PersonalMedicalHistoryScreen extends StatefulWidget {
  const PersonalMedicalHistoryScreen({Key? key}) : super(key: key);

  @override
  _PersonalMedicalHistoryScreenState createState() =>
      _PersonalMedicalHistoryScreenState();
}

class _PersonalMedicalHistoryScreenState
    extends State<PersonalMedicalHistoryScreen> {
  List<Map<String, dynamic>> _medicalRecords = [];

  @override
  void initState() {
    super.initState();
    _loadMedicalRecords();
  }

  // Load medical records from SharedPreferences
  Future<void> _loadMedicalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'medical_records';
    final List<String> storedRecords = prefs.getStringList(key) ?? [];

    setState(() {
      _medicalRecords = storedRecords.map((record) {
        final Map<String, dynamic> recordMap = jsonDecode(record);
        return {
          'title': recordMap['title'],
          'details': recordMap['details'],
        };
      }).toList();
    });
  }

  // Save updated records to SharedPreferences
  Future<void> _updatePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'medical_records';
    final List<String> storedRecords = _medicalRecords.map((record) {
      return jsonEncode(record);
    }).toList();
    await prefs.setStringList(key, storedRecords);
  }

  // Add a new medical record
  void _addMedicalRecord(Map<String, dynamic> newRecord) async {
    setState(() {
      _medicalRecords.add(newRecord);
    });
    await _updatePreferences(); // Save the updated list to SharedPreferences
  }

  // Edit a medical record
  void _editMedicalRecord(int index, Map<String, dynamic> updatedRecord) async {
    setState(() {
      _medicalRecords[index] = updatedRecord;
    });
    await _updatePreferences(); // Save the updated list to SharedPreferences
  }

  // Delete a medical record
  void _deleteMedicalRecord(int index) async {
    setState(() {
      _medicalRecords.removeAt(index);
    });
    await _updatePreferences(); // Save the updated list to SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Medical History',
            style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _medicalRecords.isEmpty
                  ? const Center(
                      child: Text(
                      'No records found.\nTap "Add Record" to create one.',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ))
                  : ListView.builder(
                      itemCount: _medicalRecords.length,
                      itemBuilder: (context, index) {
                        final record = _medicalRecords[index];
                        return MedicalCard(
                          title: record['title'],
                          details: Map<String, String>.from(record['details']),
                          onEdit: () => _editMedicalRecord(index, record),
                          onDelete: () => _deleteMedicalRecord(index),
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final newRecord = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AddPersonalMedicalRecordScreen(),
                  ),
                );
                if (newRecord != null) {
                  _addMedicalRecord(newRecord);
                }
              },
              icon: const Icon(
                Icons.add,
                size: 30,
              ),
              label: const Text(
                'Add Record',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicalCard extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicalCard({
    Key? key,
    required this.title,
    required this.details,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return {'edit', 'delete'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...details.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(entry.value,
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
