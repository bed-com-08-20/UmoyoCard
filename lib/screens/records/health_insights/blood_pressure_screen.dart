import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BloodPressureRecord {
  int systolic;
  int diastolic;
  DateTime date;
  String category;
  Color color;

  BloodPressureRecord({
    required this.systolic,
    required this.diastolic,
    required this.date,
    required this.category,
    required this.color,
  });
  // Convert BloodPressureRecord to a Map (JSON format)
  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'date': date.toIso8601String(),
      'category': category,
      // ignore: deprecated_member_use
      'color': color.value, // Store color as integer
    };
  }

  // Convert Map to BloodPressureRecord
  static BloodPressureRecord fromMap(Map<String, dynamic> map) {
    return BloodPressureRecord(
      systolic: map['systolic'],
      diastolic: map['diastolic'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      color: Color(map['color']),
    );
  }

  static String getCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return "Normal";
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return "Elevated";
    if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) return "Hypertension Stage 1";
    if (systolic >= 140 && systolic <= 180 ||
        diastolic >= 90 && diastolic <= 120) return "Hypertension Stage 2";
    if (systolic > 180 || diastolic > 120) return "Hypertensive Crisis";
    return "Not in range";
  }
}

// ignore: use_key_in_widget_constructors
class BloodPressureScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _BloodPressureScreenState createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  List<BloodPressureRecord> records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // Load records from SharedPreferences
  void _loadRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedRecords =
        prefs.getStringList('bloodPressureRecords') ?? [];

    setState(() {
      records = savedRecords
          .map((record) => BloodPressureRecord.fromMap(jsonDecode(record)))
          .toList();
    });
  }

  // Save records to SharedPreferences
  // ignore: unused_element
  void _saveRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recordsToSave =
        records.map((record) => jsonEncode(record.toMap())).toList();
    await prefs.setStringList('bloodPressureRecords', recordsToSave);
  }

  void addOrEditRecord({int? index}) {
    int systolicValue = index != null ? records[index].systolic : 120;
    int diastolicValue = index != null ? records[index].diastolic : 80;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null
              ? "Add Blood Pressure Record"
              : "Edit Blood Pressure Record"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: "Systolic"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      systolicValue = int.tryParse(value) ?? systolicValue,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "Diastolic"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      diastolicValue = int.tryParse(value) ?? diastolicValue,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  String category = BloodPressureRecord.getCategory(
                      systolicValue, diastolicValue);
                  Color categoryColor = category == "Normal"
                      ? Colors.green
                      : category == "Hypertension Stage 1"
                          ? Colors.orange
                          : category == "Hypertension Stage 2"
                              ? Colors.black
                              : category == "Hypertensive Crisis"
                                  ? Colors.red
                                  : Colors.blue;

                  if (index == null) {
                    records.insert(
                        0,
                        BloodPressureRecord(
                          systolic: systolicValue,
                          diastolic: diastolicValue,
                          date: DateTime.now(),
                          category: category,
                          color: categoryColor,
                        ));
                  } else {
                    records[index] = BloodPressureRecord(
                      systolic: systolicValue,
                      diastolic: diastolicValue,
                      date: DateTime.now(),
                      category: category,
                      color: categoryColor,
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: Text(index == null ? "Add" : "Save"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this record?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  records.removeAt(index);
                  _saveRecords();
                });
                Navigator.pop(context);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Pressure', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text("Blood Pressure Overview",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  // ignore: sized_box_for_whitespace
                  Container(
                    height: 200, // Prevents overflow
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: records.asMap().entries.map((entry) {
                          int index = entry.key;
                          BloodPressureRecord record = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: record.systolic.toDouble(),
                                color: record.color,
                                width: 12,
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (records.isNotEmpty)
              SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: records.asMap().entries.map((entry) {
                      int index = entry.key;
                      BloodPressureRecord record = entry.value;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: record.color),
                          title: Text(
                              "${record.systolic}/${record.diastolic} mmHg"),
                          subtitle: Text(
                              "${record.category}\n${record.date.day}-${record.date.month}-${record.date.year}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () =>
                                      addOrEditRecord(index: index),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: addOrEditRecord,
              // ignore: sort_child_properties_last
              child: Text("+ Add Record", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
