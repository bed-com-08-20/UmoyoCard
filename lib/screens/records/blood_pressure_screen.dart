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
  
  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'date': date.toIso8601String(),
      'category': category,
      'color': color.value,
    };
  }

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
    if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) return "Hypertension Stage 1";
    if (systolic >= 140 && systolic <= 180 || diastolic >= 90 && diastolic <=120) return "Hypertension Stage 2";
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

  void _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordsJson = records.map((record) => jsonEncode(record.toMap())).toList();
    prefs.setStringList('records', recordsJson);
  }

  void _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? recordsJson = prefs.getStringList('records');
    if (recordsJson != null) {
      setState(() {
        records = recordsJson.map((json) => BloodPressureRecord.fromMap(jsonDecode(json))).toList();
      });
    }
  }

  void addOrEditRecord({int? index}) {
    int systolicValue = index != null ? records[index].systolic : 120;
    int diastolicValue = index != null ? records[index].diastolic : 80;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? "Add Blood Pressure Record" : "Edit Blood Pressure Record"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: "Systolic"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => systolicValue = int.tryParse(value) ?? systolicValue,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "Diastolic"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => diastolicValue = int.tryParse(value) ?? diastolicValue,
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
                  String category = BloodPressureRecord.getCategory(systolicValue, diastolicValue);
                  Color categoryColor = category == "Normal"
                      ? Colors.green
                      : category=="Hypertension Stage 1"
                          ? Colors.orange
                        : category== "Hypertension Stage 2"
                          ? Colors.black 
                          : category == "Hypertensive Crisis"
                              ? Colors.red
                              : Colors.blue;

                  if (index == null) {
                    records.insert(0, BloodPressureRecord(
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
                  _saveRecords();
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
  
  bool _isWithinEditTime(DateTime date) {
    return DateTime.now().difference(date).inMinutes <= 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Pressure', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // ignore: avoid_unnecessary_containers
          Container(
            child: SingleChildScrollView(
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
                        Text("Blood Pressure Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        // ignore: sized_box_for_whitespace
                        Container(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: true),
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                ],
              ),
            ),
          ),
           SizedBox(height: 16),
          // The most recent record (fixed at the bottom of the screen)
          if (records.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: records.first.color),
                  title: Text("${records.first.systolic}/${records.first.diastolic} mmHg"),
                  subtitle: Text("${records.first.category}\n${records.first.date.day}-${records.first.date.month}-${records.first.date.year}"),
                  trailing: PopupMenuButton<int>(
                    onSelected: (value) {
                      if (value == 0) {
                        addOrEditRecord(index: 0);
                      } else if (value == 1) {
                        _confirmDelete(0);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 0,
                        child: Text("Edit", style: TextStyle(color: _isWithinEditTime(records.first.date) ? Colors.black : Colors.grey)),
                      ),
                      PopupMenuItem(
                        value: 1,
                        child: Text("Delete", style: TextStyle(color: _isWithinEditTime(records.first.date) ? Colors.black : Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // The rest of the records (scrollable)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: records.length > 1 
                    ? records.sublist(1).asMap().entries.map((entry) {
                        int index = entry.key + 1; // +1 because we're using sublist(1)
                        BloodPressureRecord record = entry.value;
                        bool canEdit = _isWithinEditTime(record.date);
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: record.color),
                            title: Text("${record.systolic}/${record.diastolic} mmHg"),
                            subtitle: Text("${record.category}\n${record.date.day}-${record.date.month}-${record.date.year}"),
                            trailing: PopupMenuButton<int>(
                              onSelected: (value) {
                                if (value == 0) {
                                  addOrEditRecord(index: index);
                                } else if (value == 1) {
                                  _confirmDelete(index);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 0,
                                  child: Text("Edit", style: TextStyle(color: canEdit ? Colors.black : Colors.grey)),
                                ),
                                PopupMenuItem(
                                  value: 1,
                                  child: Text("Delete", style: TextStyle(color: canEdit ? Colors.black : Colors.grey)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList()
                    : [SizedBox.shrink()], // Empty widget if no additional records
              ),
            ),
          ),
          
          // Add Record button (fixed at the bottom)
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: addOrEditRecord,
              // ignore: sort_child_properties_last
              child: Text("+ Add Record", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}