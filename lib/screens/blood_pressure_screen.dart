import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


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

  static String getCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return "Normal";
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return "Elevated";
    if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) return "Hypertension Stage 1";
    if (systolic >= 140 || diastolic >= 90) return "Hypertension Stage 2";
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

  void addOrEditRecord({int? index}) {
    int systolicValue = index != null ? records[index].systolic : 120;
    int diastolicValue = index != null ? records[index].diastolic : 80;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? "Add Blood Pressure Record" : "Edit Blood Pressure Record"),
          content: Column(
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
                      : category.contains("Hypertension")
                          ? Colors.orange
                          : category == "Hypertensive Crisis"
                              ? Colors.red
                              : Colors.blue;

                  if (index == null) {
                    records.add(BloodPressureRecord(
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

  void deleteRecord(int index) {
    setState(() {
      records.removeAt(index);
    });
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
                  Text("Blood Pressure Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  // ignore: sized_box_for_whitespace
                  Container(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
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
              ...records.asMap().entries.map((entry) {
                int index = entry.key;
                BloodPressureRecord record = entry.value;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: record.color),
                    title: Text("${record.systolic}/${record.diastolic} mmHg"),
                    subtitle: Text("${record.category}\n${record.date.day}-${record.date.month}-${record.date.year}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => addOrEditRecord(index: index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteRecord(index),
                        ),
                      ],
                    ),
                  ),
                );
              // ignore: unnecessary_to_list_in_spreads
              }).toList(),
              
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
