import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
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
    _loadRecords();
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

  void _loadRecords() async {
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
              backgroundColor: _getStatusColor(record['status']),
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
                Text(record['status']),
                SizedBox(height: 5),
                Text(_formatDateTime(record['date'])),
              ],
            ),
            Spacer(),
            _buildEllipsisMenu(index),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(int index) {
    setState(() {
      records.removeAt(index);
      _saveRecords();
      _updateAvailableMonths();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Record deleted successfully!')),
    );
  }

  void _confirmDeleteRecord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteRecord(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _isEditingAllowed(int index) {
    if (index >= records.length) return false;
    final record = records[index];
    final creationTime =
        DateTime.fromMillisecondsSinceEpoch(record['timestamp'] ?? 0);
    final currentTime = DateTime.now();
    return currentTime.difference(creationTime).inMinutes <= 3;
  }

  String _formatDateTime(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareRecord(int index) {
    if (index >= records.length) return;

    final record = records[index];
    final dateTime = DateTime.parse(record['date']).toLocal();
    final formattedDate =
        '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    final shareText = '''
      Blood Sugar Record:
      - Blood sugar: ${record['value']} mmol/L
      - Status: ${record['status']}
      - Date and Time: $formattedDate
      ''';

    Share.share(shareText);
  }

  Widget _buildEllipsisMenu(int index) {
    final canEdit = _isEditingAllowed(index);

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit' && canEdit) {
          _showEditRecordDialog(index);
        } else if (value == 'delete' && canEdit) {
          _confirmDeleteRecord(index);
        } else if (value == 'share') {
          _shareRecord(index);
        } else if (!canEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Editing allowed only within 5 minutes of creation')),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'share',
          height: 40,
          child: Text('Share'),
        ),
        PopupMenuItem(
            value: 'edit',
            enabled: canEdit,
            height: 40,
            child: Text(
              'Edit',
              style: TextStyle(
                color: canEdit ? null : Colors.grey,
              ),
            )),
        PopupMenuItem(
            value: 'delete',
            enabled: canEdit,
            height: 40,
            child: Text(
              'Delete',
              style: TextStyle(
                color: canEdit ? null : Colors.grey,
              ),
            )),
      ],
    );
  }

  void _showEditRecordDialog(int index) {
    TextEditingController valueController =
        TextEditingController(text: records[index]['value'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: 'Blood Sugar Level (mmol/L)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double newValue = double.tryParse(valueController.text) ?? 0.0;

              try {
                String newStatus = _determineStatus(newValue);

                setState(() {
                  records[index]['value'] = newValue;
                  records[index]['status'] = newStatus;
                  _saveRecords();
                });

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Invalid value! Please enter a valid blood sugar level.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog() {
    TextEditingController valueController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Record'),
        content: TextField(
          controller: valueController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Blood Sugar Level (mmol/L)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double value = double.tryParse(valueController.text) ?? 0.0;

              try {
                String status = _determineStatus(value);

                setState(() {
                  records.insert(0, {
                    'value': value,
                    'status': status,
                    'date': DateTime.now().toLocal().toString(),
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });
                  _saveRecords();
                  _updateAvailableMonths();
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Invalid value! Please enter a valid blood sugar level. ')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                      }))),
          borderData: FlBorderData(show: true),
          barGroups: displayRecords.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value['value'],
                  color: _getStatusColor(entry.value['status']),
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

  Widget _buildLatestRecordCard() {
    if (records.isEmpty) {
      return Text("No records available yet.");
    }
    return _buildRecordCard(records[0], 0);
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
                // if (records.isNotEmpty &&
                //     DateTime.parse(records[0]['date']).month ==
                //         _currentViewDate.month &&
                //     DateTime.parse(records[0]['date']).year ==
                //         _currentViewDate.year)
                // _buildLatestRecordCard(),
              ],
            ),
          ),

          _buildPreviousRecordsList(),
          SizedBox(height: 10),

          // Add Record Button
          Container(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _showAddRecordDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child:
                  Text('+ Add Record', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
