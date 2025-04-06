import 'package:flutter/material.dart';
import 'package:umoyocard/screens/login/loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:umoyocard/providers/password_providers.dart';
import 'package:umoyocard/screens/login/login_screen.dart';
import 'package:umoyocard/screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Use your Firebase options here
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => PasswordProvider(),
      child: const MyApp(),
    ),
  );
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
        '/loading': (context) => LoadingScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
