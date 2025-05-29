import 'package:flutter/material.dart';
import 'package:umoyocard/screens/login/loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:umoyocard/providers/password_providers.dart';
import 'package:umoyocard/screens/login/login_screen.dart';
import 'package:umoyocard/screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => PasswordProvider(),
      child: const MyApp(initialRoute: '/login',),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required String initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UmoyoCard',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/login', // Default screen when app starts
      routes: {
        '/login': (context) => const LoginScreen(),
        '/loading': (context) => LoadingScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}