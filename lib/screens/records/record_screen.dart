import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:umoyocard/screens/profile/profile_header.dart';
import 'package:umoyocard/screens/records/dashboard_screen.dart';
import 'package:umoyocard/screens/records/health_insights/health_insights.dart';
import 'package:umoyocard/screens/records/health_insights/insights_prediction.dart';
import 'package:umoyocard/screens/records/medica_history/medical_history.dart';
import 'package:umoyocard/screens/records/shared_data_record.dart';
import 'package:umoyocard/screens/records/timeline_screen.dart';
import 'package:umoyocard/services/fhir_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                          'Predicitive Analytics',
                          Icons.insights,
                          DashboardScreen(),
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
                          'Share Data',
                          Icons.share,
                          _buildShareDataScreen(
                              context), // New Share Data screen
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

  Widget _buildShareDataScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Share Data',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: const ShareDataForm(),
    );
  }
}

class ShareDataForm extends StatefulWidget {
  const ShareDataForm({super.key});
  @override
  State<ShareDataForm> createState() => _ShareDataFormState();
}

class _ShareDataFormState extends State<ShareDataForm> {
  List<String> savedTexts = [];
  List<String> savedImages = [];
  List<String> savedDates = [];
  int? _selectedIndex; // To keep track of the selected timeline item
  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedTexts = prefs.getStringList('savedTexts') ?? [];
      savedImages = prefs.getStringList('savedImages') ?? [];
      savedDates = prefs.getStringList('savedDates') ?? [];
    });
  }

  Future<void> _sendSelectedToFHIR() async {
    if (_selectedIndex != null && _selectedIndex! < savedTexts.length) {
      final text = savedTexts[_selectedIndex!];
      final image = _selectedIndex! < savedImages.length
          ? savedImages[_selectedIndex!]
          : '';
      await FHIRService.sendDocumentToFHIR(
        documentText: text,
        imagePath: image,
        context: context,
      );
      setState(() {
        _selectedIndex = null; // Reset selection after sending
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a timeline entry to share')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select prescription to Share with FHIR',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: savedTexts.length,
              itemBuilder: (context, index) {
                final hasImage = index < savedImages.length;
                final date = index < savedDates.length
                    ? DateTime.parse(savedDates[index]).toLocal()
                    : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  color: _selectedIndex == index ? Colors.teal.shade100 : null,
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    title: Text(savedTexts[index].isNotEmpty
                        ? savedTexts[index]
                        : 'No Text'),
                    subtitle: date != null
                        ? Text(DateFormat('MMM dd, yyyy - HH:mm').format(date))
                        : const Text('No Date'),
                    leading: hasImage
                        ? const Icon(Icons.image)
                        : const Icon(Icons.text_snippet),
                    trailing: _selectedIndex == index
                        ? const Icon(Icons.check_circle, color: Colors.teal)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _sendSelectedToFHIR,
              child: const Text(
                'Send Selected Data to FHIR',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
