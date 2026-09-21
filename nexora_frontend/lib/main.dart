import 'package:flutter/material.dart';
import 'login_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// The app ALWAYS starts at the login page. Any previously stored session is
  /// wiped first, so a stale token can never drop the user straight into a
  /// dashboard before they have logged in.
  Future<void> _bootstrap() async {
    await ApiService.loadSavedServerUrl();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await ApiService.clearSession();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "welcome to Amirhosein's project",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // 👇 Replace with your image if desired (remove const)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/1.jpg',
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),
              LinearProgressIndicator(
                backgroundColor: Colors.blue.shade100,
                color: Colors.blue,
                minHeight: 6,
              ),
              const SizedBox(height: 20),
              Text(
                "Loading...",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}