import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/records/medica_history/add_family_medical_history.dart';
import 'dart:convert';

class FamilyMedicalHistoryScreen extends StatefulWidget {
  const FamilyMedicalHistoryScreen({super.key});

  @override
  _FamilyMedicalHistoryScreenState createState() =>
      _FamilyMedicalHistoryScreenState();
}

class _FamilyMedicalHistoryScreenState extends State<FamilyMedicalHistoryScreen> {
  List<Map<String, dynamic>> _familyMedicalRecords = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyMedicalRecords();
  }

  // Load records from SharedPreferences
  Future<void> _loadFamilyMedicalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedRecords = prefs.getStringList('family_medical_records') ?? [];

    setState(() {
      _familyMedicalRecords = storedRecords.map((record) {
        return jsonDecode(record) as Map<String, dynamic>;
      }).toList();
    });
  }

  // Save records to SharedPreferences
  Future<void> _updatePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedRecords =
    _familyMedicalRecords.map((record) => jsonEncode(record)).toList();
    await prefs.setStringList('family_medical_records', storedRecords);
  }

  // Add a new record
  void _addFamilyMedicalRecord(Map<String, dynamic> newRecord) async {
    setState(() {
      _familyMedicalRecords.add(newRecord);
    });
    await _updatePreferences();
  }

  // Edit a record
  void _editFamilyMedicalRecord(int index, Map<String, dynamic> updatedRecord) async {
    setState(() {
      _familyMedicalRecords[index] = updatedRecord;
    });
    await _updatePreferences();
  }

  // Delete a record
  void _deleteFamilyMedicalRecord(int index) async {
    setState(() {
      _familyMedicalRecords.removeAt(index);
    });
    await _updatePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Medical History', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _familyMedicalRecords.isEmpty
                  ? const Center(
                  child: Text(
                    'No records found.\nTap "Add Record" to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ))
                  : ListView.builder(
                itemCount: _familyMedicalRecords.length,
                itemBuilder: (context, index) {
                  final record = _familyMedicalRecords[index];
                  return MedicalCard(
                    title: record['title'],
                    details: Map<String, String>.from(record['details']),
                    onEdit: () => _editFamilyMedicalRecord(index, record),
                    onDelete: () => _deleteFamilyMedicalRecord(index),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final newRecord = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFamilyMedicalHistoryScreen(),
                  ),
                );
                if (newRecord != null) {
                  _addFamilyMedicalRecord(newRecord);
                }
              },
              icon: const Icon(Icons.add, size: 30),
              label: const Text(
                'Add Record',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
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
