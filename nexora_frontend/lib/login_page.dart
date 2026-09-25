import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'create_account_page.dart';
import 'reset_password_page.dart';
import 'services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaInputController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();

  String _captchaText = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _loadServerUrl();
  }

  /// Accepts `host`, `host:8000`, `http(s)://host[:port][/anything]` and
  /// returns a URL ApiService can use as-is: scheme + host + `/api`.
  /// Applied on load too, so old saved values (e.g. missing `/api`)
  /// heal themselves without the user touching anything.
  String _normalizeServerUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Local/LAN addresses usually serve plain http; public hosts get https.
      final looksLocal = RegExp(r'^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(url);
      url = '${looksLocal ? 'http' : 'https'}://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    var path = uri.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    // The base must end with exactly one '/api' -- append it unless already there.
    if (!path.endsWith('/api')) {
      path = path.isEmpty ? '/api' : '$path/api';
    }
    // Rebuild as a plain string: Uri.replace() renders empty query/fragment
    // markers ('?#' / '#') into the URL, which silently break path appending
    // (e.g. 'host/api?#/auth/login/' hits the wrong endpoint).
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port$path';
  }

  Future<void> _loadServerUrl() async {
    final url = await ApiService.getServerUrl();
    final normalized = _normalizeServerUrl(url ?? ApiService.baseUrl);
    // Self-heal: an old saved value without /api (or otherwise malformed)
    // is persisted in fixed form so the app actually uses it.
    if (url != null && normalized != url) {
      await ApiService.setServerUrl(normalized);
    }
    if (mounted) {
      setState(() => _serverController.text = normalized);
    }
  }

  /// Lets the hosted web build (GitHub Pages) point at any running backend
  /// without a rebuild. Saved so it sticks across reloads.
  Future<void> _editServer() async {
    final controller = TextEditingController(text: _serverController.text);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API base URL',
                hintText: 'http://192.168.1.20:8000/api',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Just the host also works (e.g. my-api.onrender.com) -- /api is added automatically. Server must allow CORS from this app.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (saved == null) return; // cancelled
    final normalized = _normalizeServerUrl(saved);
    await ApiService.setServerUrl(normalized);
    if (mounted) {
      setState(() => _serverController.text = ApiService.baseUrl);
      _showSnackBar('Server saved: ${ApiService.baseUrl}', isError: false);
    }
  }

  void _generateCaptcha() {
    int randomNum = 1000 + DateTime.now().millisecondsSinceEpoch % 9000;
    setState(() {
      _captchaText = randomNum.toString();
    });
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String captchaInput = _captchaInputController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password');
      return;
    }
    if (captchaInput != _captchaText) {
      _showSnackBar('Invalid CAPTCHA');
      _generateCaptcha();
      _captchaInputController.clear();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.login(email, password);
      Navigator.pop(context);

      final userData = result['user'];
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Get role and convert to lowercase for comparison
      final roleRaw = userData['role']?.toString() ?? 'employee';
      final role = roleRaw.toLowerCase();
      final userName = userData['full_name'] ?? userData['email'] ?? 'User';

      // Debug output
      print('🔍 Role from backend (raw): $roleRaw');
      print('🔍 Role (lowercase): $role');
      print('🔍 User: $userName');

      // Check if role is owner or admin (case-insensitive)
      if (role == 'owner' || role == 'admin') {
        // Navigate to Admin Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
          (route) => false,
        );
      } else {
        // Navigate to User Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => UserDashboard(
              username: userName,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('Login failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 80, color: Colors.blue.shade700),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please sign in to continue',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: _editServer,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Server (tap to change)',
                          prefixIcon: Icon(Icons.dns, color: Colors.blue.shade700),
                          suffixIcon: Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _serverController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.blue.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _captchaText,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.blue.shade800),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, size: 20, color: Colors.blue.shade700),
                                onPressed: _generateCaptcha,
                                tooltip: 'Refresh CAPTCHA',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
                            );
                          },
                          child: Text('Forgot password?', style: TextStyle(color: Colors.blue.shade700)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                            );
                            ScaffoldMessenger.of(context).clearSnackBars();
                          },
                          child: Text('Create new account', style: TextStyle(color: Colors.blue.shade700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}