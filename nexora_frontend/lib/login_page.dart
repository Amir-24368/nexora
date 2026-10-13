import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'create_account_page.dart';
import 'reset_password_page.dart';
import 'services/api_service.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha(true);
    _loadServerUrl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _captchaInputController.dispose();
    _serverController.dispose();
    super.dispose();
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
      builder: (dialogContext) => nxDialog(
        context: dialogContext,
        title: 'API server',
        leadingIcon: const NxIconBlock(icon: Icons.dns_rounded, color: Color(0xFF3B9DDB), size: 40),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NxTextField(controller: controller, label: 'API base URL', hint: 'http://192.168.1.20:8000/api'),
            const SizedBox(height: 10),
            Text(
              'Just the host also works (e.g. my-api.onrender.com) - /api is added automatically. Server must allow CORS from this app.',
              style: TextStyle(fontSize: 12.5, color: nxOf(dialogContext).textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogContext)),
          NxButton(label: 'Save', onPressed: () => Navigator.pop(dialogContext, controller.text.trim())),
        ],
      ),
    );
    if (saved == null) return; // cancelled
    final normalized = _normalizeServerUrl(saved);
    await ApiService.setServerUrl(normalized);
    if (mounted) {
      setState(() => _serverController.text = ApiService.baseUrl);
      nxSnack(context, 'Server saved: ${ApiService.baseUrl}');
    }
  }

  void _generateCaptcha([bool clearInput = false]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final a = (now % 90) + 10;
    final b = ((now ~/ 97) % 90) + 10;
    setState(() {
      _captchaText = '$a$b';
      if (clearInput) _captchaInputController.clear();
    });
  }

  Future<void> _login() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final captchaInput = _captchaInputController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      nxSnack(context, 'Please enter email and password', isError: true);
      return;
    }
    if (captchaInput != _captchaText) {
      nxSnack(context, 'Invalid CAPTCHA', isError: true);
      _generateCaptcha(true);
      return;
    }

    setState(() => _busy = true);

    try {
      final result = await ApiService.login(email, password);

      final userData = result['user'];
      if (userData == null) {
        throw Exception('User data not found');
      }

      final roleRaw = userData['role']?.toString() ?? 'employee';
      final role = roleRaw.toLowerCase();
      final userName = userData['full_name'] ?? userData['email'] ?? 'User';

      if (!mounted) return;
      if (role == 'owner' || role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => UserDashboard(username: userName)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        nxSnack(context, 'Login failed: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          // Decorative glows behind the card.
          const Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: Color(0x337C3AED), size: 320),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _Glow(
              color: palette.isDark ? const Color(0x224F46E5) : const Color(0x264F46E5),
              size: 260,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: NxCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const NxLogo(size: 40),
                            const Spacer(),
                            const NxThemeToggle(),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Welcome back',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: palette.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue to your store',
                          style: TextStyle(fontSize: 14, color: palette.textMuted),
                        ),
                        const SizedBox(height: 26),
                        NxTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        NxTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: palette.textMuted),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // CAPTCHA row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: NxTextField(
                                controller: _captchaInputController,
                                label: 'Enter CAPTCHA',
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Rendered captcha chip
                            InkWell(
                              onTap: () => _generateCaptcha(true),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: palette.primarySoft,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _captchaText,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 5,
                                        color: palette.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.refresh_rounded, size: 18, color: palette.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        NxButton(label: _busy ? 'Signing in...' : 'Sign in', onPressed: _busy ? null : _login, height: 52, expanded: true),
                        const SizedBox(height: 14),
                        // Server pill
                        InkWell(
                          onTap: _editServer,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.dns_rounded, size: 15, color: palette.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _serverController.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: palette.textMuted),
                                  ),
                                ),
                                Icon(Icons.edit_outlined, size: 14, color: palette.textMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPasswordPage())),
                              child: Text('Forgot password?', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w600)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountPage())),
                              child: Text('Create account', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w600)),
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
        ],
      ),
    );
  }
}

/// Soft radial color blob used as login-background decoration.
class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])),
      ),
    );
  }
}
