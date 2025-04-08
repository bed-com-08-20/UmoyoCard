import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:umoyocard/screens/login/login_screen.dart';
import 'package:umoyocard/screens/home/home_screen.dart';
import 'package:umoyocard/screens/login/create_account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/create-account': (context) => const CreateAccount(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
