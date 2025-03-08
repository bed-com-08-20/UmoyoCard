import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:umoyocard/screens/login_screen.dart';

void main() {
  Firebase.initializeApp(options:const FirebaseOptions( 
     apiKey: "AIzaSyDIa9uiyA3gJJOt8MH2SfgRvFRtCnlx0RA",
    authDomain: "umoyocard.firebaseapp.com",
    projectId: "umoyocard",
    storageBucket: "umoyocard.firebasestorage.app",
    messagingSenderId: "988187296650",
    appId: "1:988187296650:web:e935f42a574b97cb773e73"));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UmoyoCard',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const LoginScreen(),
    );
  }
}
