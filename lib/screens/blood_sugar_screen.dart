import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/home_screen.dart';

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

  void _toggleShowAllRecords() {
    setState(() {
      showAllRecords = !showAllRecords;
    });
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
      });
    }
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
              String? status;

              //determine status
              if (value < 2.8) {
                status = 'Below';
              } else if (value >= 2.8 && value < 3.9) {
                status = 'Low';
              } else if (value >= 3.9 && value <= 5.6) {
                status = 'Normal';
              } else if (value >= 5.7 && value <= 6.9) {
                status = 'Prediabetes';
              } else if (value >= 7.0 && value >= 8.0) {
                status = 'Diabetes';
              }

              if (status != null) {
                setState(() {
                  records.insert(0, {
                    'value': value,
                    'status': status,
                    'date': DateTime.now().toIso8601String().substring(0, 10),
                  });
                  _saveRecords();
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Invalid value! Please enter a valid blood sugar level. ')));
              }
            },
            child: Text('Add'),
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
          baselineY: 30,
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
                  ))),
          borderData: FlBorderData(show: true),
          barGroups: records.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value['value'],
                  color: Colors.blueAccent,
                  width: 18,
                  borderRadius: BorderRadius.circular(2),
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

    return Card(
      surfaceTintColor: const Color.fromARGB(255, 245, 246, 248),
      borderOnForeground: true,
      semanticContainer: true,
      color: Colors.blue[100],
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${records[0]['value']} mmol/L',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textHeightBehavior:
                      TextHeightBehavior(applyHeightToFirstAscent: true),
                ),
                Text(records[0]['status']),
              ],
            ),
            SizedBox(height: 15),
            Text(records[0]['date']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasPreviousRecords = records.length > 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        title: Text('Blood Sugar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildBarChart(),
                  SizedBox(height: 10),
                  _buildLatestRecordCard(),

                  // Show More / Show Less logic
                  if (records.length > 1 || showAllRecords) ...[
                    if (showAllRecords)
                      Expanded(
                        child: hasPreviousRecords
                            ? ListView.builder(
                                itemCount: records.length - 1,
                                itemBuilder: (context, index) {
                                  final record = records[index + 1];
                                  return Card(
                                    color: Colors.blue[100],
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${record['value']} mmol/L',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(record['status']),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Text(record['date']),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Padding(
                                padding: EdgeInsets.all(8),
                                child: Text("No other records available"),
                              ),
                      ),
                    ElevatedButton(
                      onPressed: _toggleShowAllRecords,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        showAllRecords ? 'Show Less' : 'View More',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Add Record Button
          Container(
            padding: EdgeInsets.all(10.0),
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
