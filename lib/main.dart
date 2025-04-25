import 'package:flutter/material.dart';
import 'package:umoyocard/screens/login/loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:umoyocard/providers/password_providers.dart';
import 'package:umoyocard/screens/login/login_screen.dart';
import 'package:umoyocard/screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check login status
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => PasswordProvider(),
      child: MyApp(
        initialRoute: isLoggedIn ? '/home' : '/login',
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UmoyoCard',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/loading': (context) => LoadingScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
