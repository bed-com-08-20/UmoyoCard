import 'package:flutter/material.dart';

class RecordScreen extends StatelessWidget {
  // Make the constructor const
  const RecordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Records'),
      ),
      body: Center(
        child: Text(
          'Record Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
