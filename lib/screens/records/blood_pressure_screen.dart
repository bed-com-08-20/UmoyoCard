import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:umoyocard/screens/home/ocr_screen.dart';

class BloodPressureRecord {
  final int systolic;
  final int diastolic;
  final DateTime date;
  final String category;
  final Color color;

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

  factory BloodPressureRecord.fromMap(Map<String, dynamic> map) {
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
   static Color getColorForCategory(String category) {
    switch (category) {
      case "Normal": return Colors.green;
      case "Elevated": return Colors.blue;
      case "Hypertension Stage 1": return Colors.orange;
      case "Hypertension Stage 2": return Colors.red;
      case "Hypertensive Crisis": return Colors.red[900]!;
      default: return Colors.grey;
    }
  }

  String get formattedDate {
    final monthNames = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${date.day} ${monthNames[date.month - 1]} ${date.year}";
  }
}

class BloodPressureScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const BloodPressureScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _BloodPressureScreenState createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  List<BloodPressureRecord> records = [];
  List<BloodPressureRecord> filteredRecords = [];
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  List<int> years = [];
  
  final monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordsJson = records.map((record) => jsonEncode(record.toMap())).toList();
    prefs.setStringList('blood_pressure_records', recordsJson);
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? recordsJson = prefs.getStringList('blood_pressure_records');
    if (recordsJson != null) {
      setState(() {
        records = recordsJson
            .map((json) => BloodPressureRecord.fromMap(jsonDecode(json)))
            .toList();
        _updateYearsList();
        _filterRecords();
      });
    }
  }

  void _updateYearsList() {
    if (records.isEmpty) {
      setState(() {
        years = [selectedYear];
      });
      return;
    }

    final uniqueYears = records.map((r) => r.date.year).toSet().toList();
    uniqueYears.sort();
    years = uniqueYears;

    if (!years.contains(selectedYear)) {
      selectedYear = years.last;
    }

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
    filteredRecords = records.where((record) {
      return record.date.month == selectedMonth &&
          record.date.year == selectedYear;
    }).toList();
    filteredRecords.sort((a, b) => b.date.compareTo(a.date));
  }

  void _navigateMonth(int direction) {
    setState(() {
      if (direction == -1) {
        if (selectedMonth == 1) {
          selectedMonth = 12;
          selectedYear -= 1;
        } else {
          selectedMonth -= 1;
        }
      } else {
        if (selectedMonth == 12) {
          selectedMonth = 1;
          selectedYear += 1;
        } else {
          selectedMonth += 1;
        }
      }
      _filterRecords();
    });
  }

  void _shareRecord(BloodPressureRecord record) {
    final text = "Blood Pressure Record:\n"
        "${record.systolic}/${record.diastolic} mmHg\n"
        "Category: ${record.category}\n"
        "Date: ${record.formattedDate}";

    Share.share(text, subject: 'My Blood Pressure Record');
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this record?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
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
              child: const Text("Delete"),
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
        title: const Text('Blood Pressure', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OCRScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _navigateMonth(-1),
                        ),
                        Text(
                          '${monthNames[selectedMonth - 1]}, $selectedYear',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _navigateMonth(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView( 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (filteredRecords.isNotEmpty) ...[
                          const Text("Blood Pressure Overview",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                minY: 0,
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Record number',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    axisNameSize: 30,
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            '${value.toInt() + 1}',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    axisNameWidget: const Text(
                                        'Blood Pressure (mmHg)',
                                        style: TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    axisNameSize: 30,
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: true),
                                gridData: FlGridData(show: true),
                                barGroups: filteredRecords
                                    .asMap()
                                    .entries
                                    .map((entry) {
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
                        if (filteredRecords.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              "No data available",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: filteredRecords.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Text(
                                  "No records available",
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            ]
                          : filteredRecords.map((record) {
                              int originalIndex = records.indexWhere((r) =>
                                  r.date == record.date &&
                                  r.systolic == record.systolic &&
                                  r.diastolic == record.diastolic);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                      backgroundColor: record.color),
                                  title: Text(
                                      "${record.systolic}/${record.diastolic} mmHg"),
                                  subtitle: Text(
                                      "${record.category}\n${record.formattedDate}"),
                                  trailing: PopupMenuButton<int>(
                                    onSelected: (value) {
                                      if (value == 0) {
                                        _confirmDelete(originalIndex);
                                      } else if (value == 1) {
                                        _shareRecord(record);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 0,
                                        child: Text("Delete"),
                                      ),
                                      const PopupMenuItem(
                                        value: 1,
                                        child: Text("Share"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OCRScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Scan Blood Pressure", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}