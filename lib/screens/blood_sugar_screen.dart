import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:umoyocard/screens/home_screen.dart';

class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({super.key});

  @override
  _BloodSugarScreenState createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  List<Map<String, dynamic>> records = []; // Start with no records
  bool showAllRecords = false;

  void _toggleShowAllRecords() {
    setState(() {
      showAllRecords = !showAllRecords;
    });
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
              setState(() {
                records.insert(0, {
                  'value': double.tryParse(valueController.text) ?? 0.0,
                  'status': 'Normal',
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                });
              });
              Navigator.pop(context);
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
          barTouchData: BarTouchData(
            enabled: true,
            allowTouchBarBackDraw:true
          ),
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
                getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                maxIncluded: true,
                minIncluded: true,
                
              )    
            ),
            topTitles: AxisTitles(
              axisNameWidget: const Text("Blood Sugar Graph"),
              axisNameSize:35,
              sideTitles: SideTitles(
                showTitles: false,
                getTitlesWidget: (value, meta) => Text("Blood sugar Graph"),

              )
            ),

            bottomTitles: AxisTitles(
              axisNameWidget: const Text("Number of records"),
              axisNameSize: 25,
              sideTitles: SideTitles( 
                showTitles: true,
                reservedSize: 30,
              )
              
            )
            
          ),
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
                  borderSide:BorderSide(
                    strokeAlign: BorderSide.strokeAlignCenter,
                    width: BorderSide.strokeAlignOutside,
                    color: Colors.black
                    
                      ),
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
                Text('${records[0]['value']} mmol/L',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(records[0]['status']),
              ],
            ),
            SizedBox(height: 5),
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {       
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
          },
        ),
        title: Text('Blood Sugar', style: TextStyle(color: Colors.blue)),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${record['value']} mmol/L',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: Text('+ Add Record', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
