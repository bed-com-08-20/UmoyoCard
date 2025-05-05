import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BloodSugarScreen extends StatefulWidget {
  BloodSugarScreen({super.key});

  @override
  _BloodSugarScreenState createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  List<Map<String, dynamic>> records = []; // Start with no records
  String _currentMonthYear = '';
  List<String> _availableMonths = [];
  DateTime _currentViewDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<List<Map<String, dynamic>>> fetchBloodSugarDataFromTimeline() async {
    final prefs = await SharedPreferences.getInstance();
    final timelineTexts = prefs.getStringList('savedTexts') ?? [];
    final timelineDates = prefs.getStringList('savedDates') ?? [];
    print('Timeline Texts: $timelineTexts'); // Print the entire list
  print('Timeline Dates: $timelineDates');
    List<Map<String, dynamic>> bloodSugarReadings = [];

    // Updated regex to include "blood sugar", "sugar", "glucose", "BG", "BGL"
    final bloodSugarRegex = RegExp(
      r'(blood\s*sugar|sugar|glucose|BG|BGL)[:\s]*(\d+\.?\d*)',
      caseSensitive: false,
    );

    for (int i = 0; i < timelineTexts.length; i++) {
      final text = timelineTexts[i];
      final match = bloodSugarRegex.firstMatch(text);
      if (match != null && i < timelineDates.length) {
        final value = double.tryParse(match.group(2) ?? ''); 
        final dateString = timelineDates[i];
        if (value != null) {
          bloodSugarReadings.add({
            'value': value,
            'date': dateString,
          });
        }
      }
    }
    print('Blood Sugar Readings from Timeline: $bloodSugarReadings');
    return bloodSugarReadings;
  }


  Future<void> _loadInitialData() async {
    // Load blood sugar records saved directly by this screen
    await _loadRecords();
    // Fetch blood sugar data from the timeline
    final timelineData = await fetchBloodSugarDataFromTimeline();
    // Integrate the timeline data into your records list
    setState(() {
      // Add the timeline data to the existing records
      records.addAll(timelineData);
       print('Records after adding timeline data: $records');
      // Ensure all records have a 'status' and 'timestamp' if they don't
      records = records.map((record) {
        record['timestamp'] ??= DateTime.parse(record['date']).millisecondsSinceEpoch;
        record['status'] ??= _determineStatus(record['value']);
        return record;
      }).toList();
      // Sort the combined records by date
      records.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      _updateAvailableMonths();
      _saveRecords(); // Save the combined data if needed
    });
  }

  void _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('blood_sugar_records', jsonEncode(records));
  }

  void _updateAvailableMonths() {
    final months = <String>{};
    for (final record in records) {
      final date = DateTime.parse(record['date']);
      final monthYear = DateFormat('MMMM, yyyy').format(date);
      months.add(monthYear);
    }
    setState(() {
      _availableMonths = months.toList()..sort(_compareMonths);
      if (_availableMonths.isNotEmpty && _currentMonthYear.isEmpty) {
        _currentMonthYear = _availableMonths.first;
      }
    });
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('blood_sugar_records');
    if (savedData != null) {
      setState(() {
        records = List<Map<String, dynamic>>.from(jsonDecode(savedData));
        for (var record in records) {
          record['timestamp'] ??= DateTime.now().millisecondsSinceEpoch;
        }
        _updateAvailableMonths();
        _saveRecords();
      });
    }
  }

  String _determineStatus(double value) {
    if (value >= 1 && value < 2.8) {
      return 'Below';
    } else if (value >= 2.8 && value < 3.9) {
      return 'Low';
    } else if (value >= 3.9 && value < 5.7) {
      return 'Normal';
    } else if (value >= 5.7 && value < 6.9) {
      return 'Prediabetes';
    } else if (value >= 6.9 && value <= 90) {
      return 'Diabetes';
    }
    throw ArgumentError('Invalid blood sugar value: $value');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Below':
        return Colors.blue;
      case 'Low':
        return Colors.yellow;
      case 'Normal':
        return Colors.green;
      case 'Prediabetes':
        return Colors.orange;
      case 'Diabetes':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    return Card(
      surfaceTintColor: const Color.fromARGB(255, 245, 246, 248),
      borderOnForeground: true,
      semanticContainer: true,
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(record['status'] ?? _determineStatus(record['value'])),
              radius: 15,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record['value']} mmol/L',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(record['status'] ?? _determineStatus(record['value'])),
                SizedBox(height: 5),
                Text(_formatDateTime(record['date'])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBarChart(List<Map<String, dynamic>> displayRecords) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: displayRecords.isEmpty
          ? Center(
              child: Text(
                'No data available for ${DateFormat('MMMM, yyyy').format(_currentViewDate)}',
                style: TextStyle(fontSize: 16),
              ),
            )
          : BarChart(
              BarChartData(
                barTouchData:
                    BarTouchData(enabled: true, allowTouchBarBackDraw: true),
                baselineY: 0,
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Blood sugar (mmol/L)"),
                    axisNameSize: 30,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      maxIncluded: true,
                      minIncluded: true,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toInt().toString()),
                    ),
                  ),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                    showTitles: false,
                    maxIncluded: true,
                    minIncluded: true,
                  )),
                  topTitles: AxisTitles(
                      axisNameWidget: const Text("Blood Sugar Graph"),
                      axisNameSize: 35,
                      sideTitles: SideTitles(
                        showTitles: false,
                        getTitlesWidget: (value, meta) =>
                            Text("Blood sugar Graph"),
                      )),
                  bottomTitles: AxisTitles(
                      axisNameWidget: const Text("Number of records"),
                      axisNameSize: 25,
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text((value + 1).toInt().toString());
                          })),
                ),
                borderData: FlBorderData(show: true),
                barGroups: displayRecords.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['value'],
                        color: _getStatusColor(entry.value['status'] ?? _determineStatus(entry.value['value'])),
                        width: 18,
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                            strokeAlign: BorderSide.strokeAlignCenter,
                            width: BorderSide.strokeAlignOutside,
                            color: Colors.black),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: false,
                          toY: 10,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  int _compareMonths(String a, String b) {
    final dateA = DateFormat('MMMM, yyyy').parse(a);
    final dateB = DateFormat('MMMM, yyyy').parse(b);
    return dateB.compareTo(dateA);
  }

  void _navigateMonth(int direction) {
    setState(() {
      if (direction == -1) {
        // Previous month
        _currentViewDate =
            DateTime(_currentViewDate.year, _currentViewDate.month - 1);
      } else {
        // Next month
        _currentViewDate =
            DateTime(_currentViewDate.year, _currentViewDate.month + 1);
      }
    });
  }

  List<Map<String, dynamic>> _getRecordsForCurrentMonth() {
    return records.where((record) {
      final date = DateTime.parse(record['date']);
      return date.month == _currentViewDate.month &&
          date.year == _currentViewDate.year;
    }).toList();
  }

  Widget _buildMonthNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () => _navigateMonth(-1),
          ),
          Text(
            DateFormat('MMMM, yyyy').format(_currentViewDate),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () => _navigateMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousRecordsList() {
    final currentMonthRecords = _getRecordsForCurrentMonth();

    if (currentMonthRecords.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No records available for ${DateFormat('MMMM, yyyy').format(_currentViewDate)}',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: currentMonthRecords.length,
          itemBuilder: (context, index) {
            // Find the original index in the main records list
            final originalIndex = records.indexWhere((r) =>
                r['date'] == currentMonthRecords[index]['date'] &&
                r['value'] == currentMonthRecords[index]['value']);
            return _buildRecordCard(currentMonthRecords[index], originalIndex);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthRecords = _getRecordsForCurrentMonth();

    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Sugar', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        spacing: 0.0,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildMonthNavigationHeader(),
                _buildBarChart(currentMonthRecords),
                SizedBox(height: 10),
              ],
            ),
          ),
          _buildPreviousRecordsList(),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}