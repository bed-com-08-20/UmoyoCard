import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

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
    if (systolic >= 140 && systolic <= 180 || diastolic >= 90 && diastolic <= 120) return "Hypertension Stage 2";
    if (systolic > 180 || diastolic > 120) return "Hypertensive Crisis";
    return "Not in range";
  }

  String get formattedDate {
    final monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${date.day} ${monthNames[date.month - 1]} ${date.year}";
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
  List<BloodPressureRecord> filteredRecords = [];
  int? selectedMonth;
  int? selectedYear;
  List<int> years = [];
  final monthNames = ["January", "February", "March", "April", "May", "June", 
                     "July", "August", "September", "October", "November", "December"];

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
        _updateYearsList();
        _filterRecords();
      });
    }
  }

  void _updateYearsList() {
    if (records.isEmpty) return;
    
    final uniqueYears = records.map((r) => r.date.year).toSet().toList();
    uniqueYears.sort();
    years = uniqueYears;
    
    selectedYear = years.last;
    
    final monthsInYear = records
        .where((r) => r.date.year == selectedYear)
        .map((r) => r.date.month)
        .toSet()
        .toList();
    monthsInYear.sort();
    if (monthsInYear.isNotEmpty) {
      selectedMonth = monthsInYear.last;
    }
  }

  void _filterRecords() {
    if (selectedMonth == null || selectedYear == null) {
      filteredRecords = List.from(records);
    } else {
      filteredRecords = records.where((record) {
        return record.date.month == selectedMonth && record.date.year == selectedYear;
      }).toList();
    }
    filteredRecords.sort((a, b) => b.date.compareTo(a.date)); // Sort by newest first
  }

  void _shareRecord(BloodPressureRecord record) {
    final text = "Blood Pressure Record:\n"
                "${record.systolic}/${record.diastolic} mmHg\n"
                "Category: ${record.category}\n"
                "Date: ${record.formattedDate}";
    
    Share.share(text, subject: 'My Blood Pressure Record');
  }

  void addOrEditRecord({int? index}) {
    // Check if editing is allowed (only if within 5 minutes)
    if (index != null && !_isWithinEditTime(records[index].date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Editing is only allowed within 5 minutes of record creation")),
      );
      return;
    }

    int? systolicValue;
    int? diastolicValue;
    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();

    if (index != null) {
      systolicController.text = records[index].systolic.toString();
      diastolicController.text = records[index].diastolic.toString();
    }

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
                  controller: systolicController,
                  decoration: InputDecoration(labelText: "Systolic"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => systolicValue = int.tryParse(value),
                ),
                TextField(
                  controller: diastolicController,
                  decoration: InputDecoration(labelText: "Diastolic"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => diastolicValue = int.tryParse(value),
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
                if (systolicController.text.isEmpty && diastolicController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter values for both systolic and diastolic")),
                  );
                  return;
                } else if (systolicController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("No value specified for systolic")),
                  );
                  return;
                } else if (diastolicController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("No value specified for diastolic")),
                  );
                  return;
                }
                systolicValue = int.tryParse(systolicController.text) ?? 0;
                diastolicValue = int.tryParse(diastolicController.text) ?? 0;

                setState(() {
                  String category = BloodPressureRecord.getCategory(systolicValue!, diastolicValue!);
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
                    records.insert(0, BloodPressureRecord(
                      systolic: systolicValue!,
                      diastolic: diastolicValue!,
                      date: DateTime.now(),
                      category: category,
                      color: categoryColor,
                    ));
                  } else {
                    records[index] = BloodPressureRecord(
                      systolic: systolicValue!,
                      diastolic: diastolicValue!,
                      date: records[index].date, // Keep original date for edits
                      category: category,
                      color: categoryColor,
                    );
                  }
                  _saveRecords();
                  _updateYearsList();
                  _filterRecords();
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
    // Check if deletion is allowed (only if within 5 minutes)
    if (!_isWithinEditTime(records[index].date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deletion is only allowed within 5 minutes of record creation")),
      );
      return;
    }

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
                  _updateYearsList();
                  _filterRecords();
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
          //changes
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Card(
             elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                     Expanded(
                     child: DropdownButton<int>(
                      isExpanded: true,
                    value: selectedMonth,
                     hint: Text('Month'),
                        items: List.generate(12, (index) => index + 1).map((int month) {
                      return DropdownMenuItem<int>(
                       value: month,
                     child: Text(monthNames[month - 1]),
                           );
                        }).toList(),
                     onChanged: (int? newValue) {
                    setState(() {
                   selectedMonth = newValue;
                  _filterRecords();
                });
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedYear,
              hint: Text('Year'),
              items: years.map((int year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                     );
                  }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedYear = newValue;
                  selectedMonth = null;
                  _filterRecords();
                            });
                          },
                         ),
                       ),
                     ],
                    ),
                  ),
                 ),
             ),
           SizedBox(height: 12),   
          //changes end
          Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.lightBlue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Blood Pressure Overview", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                // ignore: sized_box_for_whitespace
                Container(
                  height: 180,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                                return Text('${value.toInt() + 1}');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                      barGroups: filteredRecords.asMap().entries.map((entry) {
                        int index = entry.key;
                        BloodPressureRecord record = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: record.systolic.toDouble(),
                              color: record.color,
                              width: 10,
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
          ),
          SizedBox(height: 12),
          if (filteredRecords.isNotEmpty)
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: filteredRecords.first.color),
                  title: Text("${filteredRecords.first.systolic}/${filteredRecords.first.diastolic} mmHg"),
                  subtitle: Text("${filteredRecords.first.category}\n${filteredRecords.first.formattedDate}"),
                  trailing: PopupMenuButton<int>(
                    onSelected: (value) {
                      int originalIndex = records.indexWhere((r) => 
                        r.date == filteredRecords.first.date && 
                        r.systolic == filteredRecords.first.systolic && 
                        r.diastolic == filteredRecords.first.diastolic);
                      
                      if (value == 0) {
                        addOrEditRecord(index: originalIndex);
                      } else if (value == 1) {
                        _confirmDelete(originalIndex);
                      } else if (value == 2) {
                        _shareRecord(filteredRecords.first);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 0,
                        enabled: _isWithinEditTime(filteredRecords.first.date),
                        child: Text("Edit", style: TextStyle(color: _isWithinEditTime(filteredRecords.first.date) ? Colors.black : Colors.grey)),
                      ),
                      PopupMenuItem(
                        value: 1,
                        enabled: _isWithinEditTime(filteredRecords.first.date),
                        child: Text("Delete", style: TextStyle(color: _isWithinEditTime(filteredRecords.first.date) ? Colors.black : Colors.grey)),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: Text("Share"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: filteredRecords.length > 1 
                    ? filteredRecords.sublist(1).map((record) {
                        bool canEdit = _isWithinEditTime(record.date);
                        int originalIndex = records.indexWhere((r) => 
                          r.date == record.date && 
                          r.systolic == record.systolic && 
                          r.diastolic == record.diastolic);
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: record.color),
                            title: Text("${record.systolic}/${record.diastolic} mmHg"),
                            subtitle: Text("${record.category}\n${record.formattedDate}"),
                            trailing: PopupMenuButton<int>(
                              onSelected: (value) {
                                if (value == 0) {
                                  addOrEditRecord(index: originalIndex);
                                } else if (value == 1) {
                                  _confirmDelete(originalIndex);
                                } else if (value == 2) {
                                  _shareRecord(record);
                                } 
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 0, 
                                  enabled: canEdit,
                                  child: Text("Edit", style: TextStyle(color: canEdit ? Colors.black : Colors.grey)),
                                ),
                                PopupMenuItem(
                                  value: 1,
                                  enabled: canEdit,
                                  child: Text("Delete", style: TextStyle(color: canEdit ? Colors.black : Colors.grey)),
                                ),
                                PopupMenuItem(
                                  value: 2,
                                  child: Text("Share"),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList()
                    : [SizedBox.shrink()],
              ),
            ),
          ),
          
          // Add Record Button
          Padding(
            padding: EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: addOrEditRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("+ Add Record", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
       ),
    );
  }
}