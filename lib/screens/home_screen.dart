import 'dart:async';
import 'package:flutter/material.dart';
import 'package:umoyocard/screens/profile_screen.dart';
import 'package:umoyocard/screens/record_screen.dart';
import 'package:umoyocard/screens/ocr_screen.dart';
import 'package:umoyocard/screens/timeline_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Removed const from widget constructors if they aren't marked as const
  final List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    RecordScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Home',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            )
          : null,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi Wadi Mkweza, welcome back!',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              'Quick Links',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            GridView.builder(
              shrinkWrap: true,
              itemCount: quickLinks.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final quickLink = quickLinks[index];
                if ((quickLink['label'] as String) == 'Recent Timeline') {
                  return RecentTimelineCard(
                    onTap: () =>
                        _handleQuickLinkTap(context, 'Recent Timeline'),
                  );
                }
                return _QuickLinkCard(
                  icon: quickLink['icon'] as IconData,
                  label: quickLink['label'] as String,
                  onTap: () => _handleQuickLinkTap(
                      context, quickLink['label'] as String),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickLinkTap(BuildContext context, String label) {
    if (label == 'Scan Health Passport') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OCRScreen()),
      );
    } else if (label == 'Recent Timeline') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TimelineScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feature for "$label" is not implemented yet.')),
      );
    }
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  _QuickLinkCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            SizedBox(height: 8.0),
            Text(label, style: TextStyle(fontSize: 14.0)),
          ],
        ),
      ),
    );
  }
}

const quickLinks = [
  {'icon': Icons.qr_code_scanner, 'label': 'Scan Health Passport'},
  {'icon': Icons.timeline, 'label': 'Recent Timeline'},
  {'icon': Icons.favorite, 'label': 'Blood Pressure'},
  {'icon': Icons.medical_services, 'label': 'Blood Sugar'},
  {'icon': Icons.monitor_heart, 'label': 'Heart Rate'},
  {'icon': Icons.accessibility, 'label': 'Weight (tikambirana izi)'},
];

/// A stateful RecentTimelineCard that retrieves and displays the latest saved text.
/// It refreshes its content periodically so that newly saved records are shown almost instantly.
class RecentTimelineCard extends StatefulWidget {
  final VoidCallback? onTap;
  const RecentTimelineCard({Key? key, this.onTap}) : super(key: key);

  @override
  _RecentTimelineCardState createState() => _RecentTimelineCardState();
}

class _RecentTimelineCardState extends State<RecentTimelineCard> {
  String _latestText = 'Loading...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLatestText();
    // Refresh every 2 seconds. Adjust the duration as needed.
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchLatestText();
    });
  }

  Future<void> _fetchLatestText() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> texts = prefs.getStringList('savedTexts') ?? [];
    setState(() {
      _latestText = texts.isNotEmpty ? texts.last : 'No recent record';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading at the very top inside the card.
            Text(
              "Recent Timeline",
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8.0),
            // Display all the text fields (without truncation).
            Text(
              _latestText,
              style: TextStyle(fontSize: 12.0, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
