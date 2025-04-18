import 'package:flutter/material.dart';
import 'package:umoyocard/screens/profile/profile_header.dart';
import 'package:umoyocard/screens/records/health_insights/health_insights.dart';
import 'package:umoyocard/screens/records/health_insights/insights_prediction.dart';
import 'package:umoyocard/screens/records/medica_history/medical_history.dart';
import 'package:umoyocard/screens/records/shared_data_record.dart';
import 'timeline_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          'Records',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: const [
          ProfileHeader(),
          SizedBox(width: 10),
        ],
      ),
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
            // Grid layout for record cards
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
                        _buildRecordCard(
                          context,
                          'Health Insights & Predicitive Analytics',
                          Icons.insights,
                          InsightsPredictionsScreen(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildRecordCard(
                          context,
                          'Medical History',
                          Icons.history,
                          const MedicalHistoryScreen(),
                        ),
                        _buildRecordCard(
                          context,
                          'Shared Data Log',
                          Icons.share,
                          SharedDataRecordScreen(),
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
