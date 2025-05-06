import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'About UmoyoCard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Replaced logo with app icon
            const Icon(
              Icons.medical_services,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'UmoyoCard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Version $appVersion',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'UmoyoCard is a mobile health application designed to help you manage your health passport, track medical records, and gain insights through predictive analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Our Mission',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'To empower individuals with easy access to their health information and provide tools for better health management through technology.',
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Connect With Us',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.language, size: 30),
                  onPressed: () => _launchURL('https://www.umoyocard.com'),
                ),
                IconButton(
                  icon: const Icon(Icons.facebook, size: 30),
                  onPressed: () => _launchURL('https://facebook.com/umoyocard'),
                ),
                IconButton(
                  icon: const Icon(Icons.campaign,
                      size: 30), // Twitter alternative
                  onPressed: () => _launchURL('https://twitter.com/umoyocard'),
                ),
                IconButton(
                  icon: const Icon(Icons.business,
                      size: 30), // LinkedIn alternative
                  onPressed: () =>
                      _launchURL('https://linkedin.com/company/umoyocard'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '© 2025 UmoyoCard. All rights reserved.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
