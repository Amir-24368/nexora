import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  void _sendResetLink() {
    String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Gmail address')),
      );
      return;
    }

    // Simulate sending reset link
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reset link sent to $email (demo)'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to login after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Enter your Gmail address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'We will send you a password reset link',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Gmail address',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendResetLink,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Send Reset Link'),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}