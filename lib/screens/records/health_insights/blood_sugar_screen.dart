import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/home/home_screen.dart';

class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({super.key});

  @override
  _BloodSugarScreenState createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  List<Map<String, dynamic>> records = []; // Start with no records
  bool showAllRecords = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('records', jsonEncode(records));
  }

  void _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('records');
    if (savedData != null) {
      setState(() {
        records = List<Map<String, dynamic>>.from(jsonDecode(savedData));
        for (var record in records) {
          record['timestamp'] ??= DateTime.now().millisecondsSinceEpoch;
        }
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
      color: _getStatusColor(record['status']).withAlpha((0.3 * 255).toInt()),
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
                Text(record['date']),
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

  Widget _buildEllipsisMenu(int index) {
    final canEdit = _isEditingAllowed(index);

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit' && canEdit) {
          _showEditRecordDialog(index);
        } else if (value == 'delete' && canEdit) {
          _confirmDeleteRecord(index);
        } else if (!canEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Editing allowed only within 5 minutes of creation')),
          );
        }

      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          enabled: canEdit, 
          height: 40, 
          child: Text('Edit', style: TextStyle(
            color: canEdit? null : Colors.grey,
          ),)
        ),
        PopupMenuItem(
          value: 'delete', 
          enabled: canEdit, 
          height: 40, 
          child: Text('Delete', style: TextStyle(
            color: canEdit? null : Colors.grey,
          ),)
        ),
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
                    'date': DateTime.now().toIso8601String().substring(0, 10),
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });
                  _saveRecords();
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

  Widget _buildBarChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
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
                    getTitlesWidget: (value, meta) => Text("Blood sugar Graph"),
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
          barGroups: records.asMap().entries.map((entry) {
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

  Widget _buildPreviousRecordsList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: records.length > 1 ? records.length - 1 : 0,
          itemBuilder: (context, index) {
            return _buildRecordCard(records[index + 1], index + 1);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
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
                _buildBarChart(),
                SizedBox(height: 10),
                _buildLatestRecordCard(),
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