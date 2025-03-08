import 'package:flutter/material.dart';
import 'package:umoyocard/screens/profile_screen.dart';
import 'package:umoyocard/screens/record_screen.dart';
import 'package:umoyocard/screens/blood_pressure_screen.dart';
import 'package:umoyocard/screens/blood_sugar_screen.dart';


// ignore: use_key_in_widget_constructors
class HomeScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ignore: prefer_final_fields
  static List<Widget> _widgetOptions = <Widget>[
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
              title: const Text(
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
        items: const <BottomNavigationBarItem>[
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

// ignore: use_key_in_widget_constructors
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hi Wadi Mkweza, welcome back!',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Quick Links',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            GridView.builder(
              shrinkWrap: true,
              itemCount: quickLinks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final quickLink = quickLinks[index];
                return _QuickLinkCard(
                  icon: quickLink['icon'] as IconData,
                  label: quickLink['label'] as String,
                  onTap: () {
                    // Navigate based on the label
                    _navigateToScreen(context, quickLink['label'] as String);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String label) {
    // Perform navigation based on the quick link label
    switch (label) {
      case 'Blood Pressure':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BloodPressureScreen()),
        );
        break;
      case 'Blood Sugar':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BloodSugarScreen()),
        );
        break;
      default:
        break;
    }
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle the onTap action
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8.0),
            Text(label, style: const TextStyle(fontSize: 14.0)),
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
