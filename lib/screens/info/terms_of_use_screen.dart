import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Terms of Use',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: January 1, 2025',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('1. Acceptance of Terms'),
            const Text(
              'By accessing or using the UmoyoCard mobile application ("App"), you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the App.',
            ),
            _buildSectionTitle('2. Description of Service'),
            const Text(
              'UmoyoCard provides a digital health passport service that allows users to scan, store, and manage health records. The App may include predictive analytics features and integration with FHIR servers for data sharing.',
            ),
            _buildSectionTitle('3. User Responsibilities'),
            const Text(
              'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You agree to provide accurate and complete information when using the App.',
            ),
            _buildSectionTitle('4. Health Information'),
            const Text(
              'The App allows you to store health-related information. We are not responsible for the accuracy of this information or any decisions made based on it. Always consult with a healthcare professional for medical advice.',
            ),
            _buildSectionTitle('5. Limitation of Liability'),
            const Text(
              'To the fullest extent permitted by law, UmoyoCard shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App.',
            ),
            _buildSectionTitle('6. Changes to Terms'),
            const Text(
              'We reserve the right to modify these terms at any time. Your continued use of the App after such changes constitutes your acceptance of the new terms.',
            ),
            const SizedBox(height: 20),
            const Text(
              'If you have any questions about these Terms of Use, please contact us through the App.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
