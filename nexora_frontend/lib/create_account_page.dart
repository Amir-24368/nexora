import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _captchaInputController = TextEditingController();

  String _captchaText = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    int randomNum = 1000 + DateTime.now().millisecondsSinceEpoch % 9000;
    setState(() {
      _captchaText = randomNum.toString();
    });
  }

  Future<void> _createAccount() async {
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String shopName = _shopNameController.text.trim();
    String password = _passwordController.text.trim();
    String confirm = _confirmController.text.trim();
    String captchaInput = _captchaInputController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Enter a valid email address');
      return;
    }
    if (username.isEmpty) {
      _showSnackBar('Enter your full name');
      return;
    }
    if (shopName.isEmpty) {
      _showSnackBar('Enter a shop name');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showSnackBar('Passwords do not match');
      return;
    }
    if (captchaInput != _captchaText) {
      _showSnackBar('Invalid CAPTCHA');
      _generateCaptcha();
      _captchaInputController.clear();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Real registration: creates the user AND their shop on the backend,
      // and stores the JWT tokens so the user lands straight in the app.
      final result = await ApiService.register(
        email: email,
        password: password,
        fullName: username,
        shopName: shopName,
      );
      if (!mounted) return;

      final userData = result['user'];
      final role = (userData?['role'] ?? 'owner').toString().toLowerCase();

      _showSnackBar('Account created successfully!', isError: false);

      Widget destination;
      if (role == 'owner' || role == 'admin') {
        destination = const AdminDashboard();
      } else {
        destination = UserDashboard(username: username);
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => destination),
          (route) => false,
        );
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      _generateCaptcha();
      _captchaInputController.clear();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            const Text('Sign up with Gmail', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Gmail address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Full name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _shopNameController,
              decoration: InputDecoration(
                labelText: 'Shop name',
                prefixIcon: const Icon(Icons.store),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _captchaInputController,
                    decoration: InputDecoration(
                      labelText: 'Enter CAPTCHA',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Text(_captchaText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _generateCaptcha,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('CREATE ACCOUNT'),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}