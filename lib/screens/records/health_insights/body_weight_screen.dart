import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeightRecord {
  double weight;
  DateTime date;

  WeightRecord({
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }

  static WeightRecord fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      weight: map['weight'],
      date: DateTime.parse(map['date']),
    );
  }
}

class WeightTrackingScreen extends StatefulWidget {
  @override
  _WeightTrackingScreenState createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  List<WeightRecord> records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedRecords = prefs.getStringList('weightRecords') ?? [];

    setState(() {
      records = savedRecords
          .map((record) => WeightRecord.fromMap(jsonDecode(record)))
          .toList();
    });
  }

  void _saveRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recordsToSave =
    records.map((record) => jsonEncode(record.toMap())).toList();
    await prefs.setStringList('weightRecords', recordsToSave);
  }

  void addOrEditRecord({int? index}) {
    double weightValue = index != null ? records[index].weight : 00.0;
    final TextEditingController controller =
    TextEditingController(text: weightValue.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title:
              Text(index == null ? "Add Weight Record" : "Edit Weight Record"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: "Weight (KG)",
                      errorText: errorText,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      double? input = double.tryParse(value);
                      setState(() {
                        if (input == null) {
                          errorText = "Please enter a valid number.";
                        } else if (input > 635) {
                          errorText = "Weight exceeds maximum human limit (635 KG).";
                        } else {
                          errorText = null;
                          weightValue = input;
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (errorText == null) {
                      setState(() {
                        if (index == null) {
                          records.insert(
                              0,
                              WeightRecord(
                                  weight: weightValue, date: DateTime.now()));
                        } else {
                          records[index] = WeightRecord(
                              weight: weightValue, date: DateTime.now());
                        }
                        _saveRecords();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(index == null ? "Add" : "Save"),
                ),
              ],
            );
          },
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
        title: Text('Weight Tracking', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
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
                  Text("Weight Progress",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Container(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: records
                                .asMap()
                                .entries
                                .map((entry) => FlSpot(entry.key.toDouble(),
                                entry.value.weight))
                                .toList(),
                            isCurved: true,
                            color: Colors.blue,
                            dotData: FlDotData(show: true),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (records.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    WeightRecord record = records[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text("${record.weight} KG"),
                        subtitle: Text(
                            "${record.date.day}-${record.date.month}-${record.date.year}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => addOrEditRecord(index: index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: addOrEditRecord,
              child: Text("+ Add Weight", style: TextStyle(fontSize: 18)),
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
