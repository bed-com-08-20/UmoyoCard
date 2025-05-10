import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Privacy Policy',
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
              'Last Updated: March 1, 2025',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('1. Information We Collect'),
            const Text(
              'We collect information you provide when using UmoyoCard, including:\n'
              '- Personal information (name, email, etc.)\n'
              '- Health passport data you scan and store\n'
              '- Usage data and analytics\n'
              '- Device information',
            ),
            _buildSectionTitle('2. How We Use Your Information'),
            const Text(
              'We use the collected information to:\n'
              '- Provide and improve our services\n'
              '- Enable health data sharing with FHIR servers\n'
              '- Perform predictive analytics\n'
              '- Communicate with you about the App\n'
              '- Ensure security and prevent fraud',
            ),
            _buildSectionTitle('3. Data Sharing'),
            const Text(
              'We may share your information with:\n'
              '- Healthcare providers through FHIR servers (with your consent)\n'
              '- Service providers who assist in operating the App\n'
              '- When required by law or to protect our rights',
            ),
            _buildSectionTitle('4. Data Security'),
            const Text(
              'We implement appropriate security measures to protect your data. However, no method of electronic storage is 100% secure, and we cannot guarantee absolute security.',
            ),
            _buildSectionTitle('5. Your Choices'),
            const Text(
              'You can:\n'
              '- Access and update your personal information\n'
              '- Delete your account and stored data\n'
              '- Opt-out of certain data collection\n'
              '- Control sharing with FHIR servers',
            ),
            _buildSectionTitle('6. Changes to This Policy'),
            const Text(
              'We may update this policy periodically. We will notify you of significant changes through the App or via email.',
            ),
            const SizedBox(height: 20),
            const Text(
              'If you have questions about our privacy practices, please contact us through the App.',
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
