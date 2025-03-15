import 'package:flutter/material.dart';

class SharedDataRecordScreen extends StatelessWidget {
  final List<Map<String, String>> sharedData = [
    {
      'data': 'Blood Test Results',
      'recipient': 'Dr. John Doe',
      'date': '2025-03-09',
    },
    {
      'data': 'Prescription for Diabetes',
      'recipient': 'Clinic A',
      'date': '2025-03-01',
    },
    {
      'data': 'Medical History',
      'recipient': 'Hospital XYZ',
      'date': '2025-02-25',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shared Data Records',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: sharedData.length,
        itemBuilder: (context, index) {
          var record = sharedData[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(record['data']!),
              subtitle: Text(
                  'Recipient: ${record['recipient']}\nDate Shared: ${record['date']}'),
              onTap: () {
                _showDetails(context, record);
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, String> record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(record['data']!),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipient: ${record['recipient']}'),
              Text('Date Shared: ${record['date']}'),
              // Add more details if necessary
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
