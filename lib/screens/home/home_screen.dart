import 'dart:async';
import 'package:flutter/material.dart';
import 'package:umoyocard/screens/profile/profile_screen.dart';
import 'package:umoyocard/screens/records/health_insights/blood_pressure_screen.dart';
import 'package:umoyocard/screens/records/health_insights/blood_sugar_screen.dart';
import 'package:umoyocard/screens/records/health_insights/body_weight_screen.dart';
import 'package:umoyocard/screens/records/record_screen.dart';
import 'package:umoyocard/screens/home/ocr_screen.dart';
import 'package:umoyocard/screens/home/qr_code_screen.dart';
import 'package:umoyocard/screens/records/timeline_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickLinkCard(
                          context,
                          'Scan Health Passport',
                          Icons.image_search,
                          () => _handleQuickLinkTap(
                              context, 'Scan Health Passport'),
                        ),
                        _buildQuickLinkCard(
                          context,
                          'Scan Barcode or QR Code',
                          Icons.qr_code_scanner,
                          () => _handleQuickLinkTap(context, 'Scan QR Code'),
                        ),
                        _buildQuickLinkCard(
                          context,
                          'Recent Timeline',
                          Icons.timeline,
                              () => _handleQuickLinkTap(context, 'Recent Timeline'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickLinkCard(
                          context,
                          'Blood Pressure',
                          Icons.favorite,
                          () => _handleQuickLinkTap(context, 'Blood Pressure'),
                        ),
                        _buildQuickLinkCard(
                          context,
                          'Body Weight',
                          Icons.scale,
                              () => _handleQuickLinkTap(context, 'Body Weight'),
                        ),
                        _buildQuickLinkCard(
                          context,
                          'Blood Sugar',
                          Icons.medical_services,
                          () => _handleQuickLinkTap(context, 'Blood Sugar'),
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

  /// Builds a quick link card. When the title is "Recent Timeline",
  /// it returns the [RecentTimelineCard] (which has the dynamic refresh functionality);
  /// otherwise it returns a standard card.
  Widget _buildQuickLinkCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    if (title == 'Recent Timeline') {
      return Expanded(
        child: RecentTimelineCard(
          onTap: onTap,
        ),
      );
    }
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 30),
              SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
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

  /// Handles the tap actions for each quick link.
  /// "Scan Health Passport" navigates to [OCRScreen],
  /// "Recent Timeline" navigates to [TimelineScreen],
  /// and other cards show a snackbar.
  void _handleQuickLinkTap(BuildContext context, String label) {
    if (label == 'Scan Health Passport') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OCRScreen()),
      );
    }
    else if (label == 'Scan QR Code') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
      );
    } else if (label == 'Recent Timeline') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TimelineScreen()),
      );
    } else if (label == 'Blood Pressure') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BloodPressureScreen()),
      );
    } else if (label == 'Body Weight') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WeightTrackingScreen()),
      );
    } else if (label == 'Blood Sugar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BloodSugarScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feature for "$label" is not implemented yet.')),
      );
    }
  }
}

class _QuickLinkCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  _QuickLinkCard({required this.icon, required this.label, this.onTap});

  @override
  State<_QuickLinkCard> createState() => _QuickLinkCardState();
}

class _QuickLinkCardState extends State<_QuickLinkCard> {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 30, color: Colors.blue),
            SizedBox(height: 8.0),
            Text(widget.label, style: TextStyle(fontSize: 14.0)),
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
  {'icon': Icons.scale, 'label': 'Body Weight'},
];

class RecentTimelineCard extends StatefulWidget {
  final VoidCallback? onTap;
  const RecentTimelineCard({super.key, this.onTap});

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
    // Refresh every 2 seconds.
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
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Recent Timeline",
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8.0),
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
