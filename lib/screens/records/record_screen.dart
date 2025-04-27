import 'package:flutter/material.dart';
import 'package:umoyocard/screens/records/dashboard_screen.dart';
import 'package:umoyocard/screens/records/share_data.dart';
import 'package:umoyocard/screens/records/timeline_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Select a Record to View or Manage",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildRecordCard(
                          context,
                          'Timeline',
                          Icons.timeline,
                          const TimelineScreen(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildRecordCard(
                          context,
                          'Predicitive Analytics',
                          Icons.insights,
                          DashboardScreen(),
                        ),
                        _buildRecordCard(
                          context,
                          'Share Data',
                          Icons.share,
                          const SharedDataRecord(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
