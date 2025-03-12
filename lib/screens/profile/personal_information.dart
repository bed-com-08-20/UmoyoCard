import 'package:flutter/material.dart';

class UpdatePersonalInfoScreen extends StatelessWidget {
  // ignore: use_super_parameters
  const UpdatePersonalInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Basic Personal Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Fullname', 'Harry Yamikani Peter', context),
                  _buildInfoRow('Date of Birth', '12/05/1998', context),
                  _buildInfoRow('Address', 'Box 320, Balaka', context),
                  _buildInfoRow('Phone Number', '+265995602273', context),
                  _buildInfoRow('Email Address', 'harrypeter@gmail.com', context),
                  _buildInfoRow('National ID', 'WZXE21Q', context),
                  _buildInfoRow('Nationality', 'Malawian', context),
                  _buildInfoRow('Gender', 'Male', context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.black87)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit $label')),
              );
            },
          ),
        ],
      ),
    );
  }
}
