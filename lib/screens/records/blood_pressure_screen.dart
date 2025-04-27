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

  Map<String, dynamic> toMap() => {
    'systolic': systolic,
    'diastolic': diastolic,
    'date': date.toIso8601String(),
    'category': category,
    'color': color.value,
  };

  factory BloodPressureRecord.fromMap(Map<String, dynamic> map) => BloodPressureRecord(
    systolic: map['systolic'],
    diastolic: map['diastolic'],
    date: DateTime.parse(map['date']),
    category: map['category'],
    color: Color(map['color']),
  );

  static String getCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return "Normal";
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return "Elevated";
    if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) 
      return "Stage 1";
    if (systolic >= 140 || diastolic >= 90) return "Stage 2";
    return "Unknown";
  }

  String get formattedDate => 
    '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

class BloodPressureScreen extends StatefulWidget {
  final String? ocrData;

  const BloodPressureScreen({Key? key, this.ocrData}) : super(key: key);

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  List<BloodPressureRecord> _records = [];
  List<BloodPressureRecord> _filteredRecords = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    if (widget.ocrData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processOCRData(widget.ocrData!);
      });
    }
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList('bp_records') ?? [];
    setState(() {
      _records = recordsJson.map((json) => 
        BloodPressureRecord.fromMap(jsonDecode(json))).toList();
      _filterRecords();
    });
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = _records.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('bp_records', recordsJson);
  }

  void _filterRecords() {
    setState(() {
      _filteredRecords = _records.where((r) => 
        r.date.month == _selectedMonth && r.date.year == _selectedYear
      ).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _processOCRData(String data) {
    final lines = data.split('\n');
    final now = DateTime.now();
    bool added = false;

    for (var line in lines) {
      line = line.trim();
      if (!line.contains('mmHg')) continue;

      final bpRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})?\s*(\d+)/(\d+)\s*mmHg');
      final match = bpRegex.firstMatch(line);
      if (match == null) continue;

      final dateStr = match.group(1);
      final systolic = int.tryParse(match.group(2)!) ?? 0;
      final diastolic = int.tryParse(match.group(3)!) ?? 0;

      DateTime date;
      if (dateStr != null) {
        final parts = dateStr.split('/');
        date = DateTime(
          int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } else {
        date = now;
      }

      final category = BloodPressureRecord.getCategory(systolic, diastolic);
      final color = _getCategoryColor(category);

      setState(() {
        _records.insert(0, BloodPressureRecord(
          systolic: systolic,
          diastolic: diastolic,
          date: date,
          category: category,
          color: color,
        ));
        added = true;
      });
    }

    if (added) {
      _saveRecords();
      _filterRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added new BP readings')),
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Normal': return Colors.green;
      case 'Elevated': return Colors.yellow;
      case 'Stage 1': return Colors.orange;
      case 'Stage 2': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _deleteRecord(int index) {
    setState(() {
      _records.removeAt(index);
      _saveRecords();
      _filterRecords();
    });
  }

  void _shareRecord(BloodPressureRecord record) {
    Share.share(
      'Blood Pressure: ${record.systolic}/${record.diastolic} mmHg\n'
      'Category: ${record.category}\n'
      'Date: ${record.formattedDate}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OCRScreen()),
            ).then((_) => _loadRecords()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildChart(),
                  _buildRecordsList(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OCRScreen()),
              ).then((_) => _loadRecords()),
              child: const Text('Scan New Reading'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_selectedMonth == 1) {
                  _selectedMonth = 12;
                  _selectedYear--;
                } else {
                  _selectedMonth--;
                }
                _filterRecords();
              });
            },
          ),
          Text(
            '${_monthNames[_selectedMonth - 1]} $_selectedYear',
            style: const TextStyle(fontSize: 18),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_selectedMonth == 12) {
                  _selectedMonth = 1;
                  _selectedYear++;
                } else {
                  _selectedMonth++;
                }
                _filterRecords();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 200,
      child:SingleChildScrollView(
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _filteredRecords.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      (value.toInt() + 1).toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          barGroups: _filteredRecords.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: record.systolic.toDouble(),
                  color: record.color,
                  width: 16,
                ),
                BarChartRodData(
                  toY: record.diastolic.toDouble(),
                  color: record.color.withOpacity(0.6),
                  width: 16,
                ),
              ],
            );
          }).toList(),
        ),
      ),
     ),
    );
  }

  Widget _buildRecordsList() {
    if (_filteredRecords.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No records for selected month'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: record.color),
            title: Text('${record.systolic}/${record.diastolic} mmHg'),
            subtitle: Text('${record.category} • ${record.formattedDate}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 0,
                  child: Text('Delete'),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Text('Share'),
                ),
              ],
              onSelected: (value) {
                if (value == 0) {
                  _deleteRecord(_records.indexWhere((r) => 
                    r.date == record.date && 
                    r.systolic == record.systolic && 
                    r.diastolic == record.diastolic
                  ));
                } else if (value == 1) {
                  _shareRecord(record);
                }
              },
            ),
          ),
        );
      },
    );
  }
}