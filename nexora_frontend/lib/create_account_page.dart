import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
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

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _shopNameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _captchaInputController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final a = (now % 90) + 10;
    final b = ((now ~/ 97) % 90) + 10;
    setState(() {
      _captchaText = '$a$b';
    });
    _captchaInputController.clear();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_captchaInputController.text.trim() != _captchaText) {
      nxSnack(context, 'Invalid CAPTCHA', isError: true);
      _generateCaptcha();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Real registration: creates the user AND their shop on the backend,
      // and stores the JWT tokens so the user lands straight in the app.
      final result = await ApiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _usernameController.text.trim(),
        shopName: _shopNameController.text.trim(),
      );
      if (!mounted) return;

      final userData = result['user'];
      final role = (userData?['role'] ?? 'owner').toString().toLowerCase();

      nxSnack(context, 'Account created successfully!');

      Widget destination;
      if (role == 'owner' || role == 'admin') {
        destination = const AdminDashboard();
      } else {
        destination = UserDashboard(username: _usernameController.text.trim());
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
      nxSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      _generateCaptcha();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        leading: const NxBackButton(),
        title: const Text('Create account'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: NxCard(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const NxIconBlock(icon: Icons.person_add_alt_1_rounded, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Join Nexora', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                              Text('Set up your shop in under a minute', style: TextStyle(fontSize: 13, color: palette.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    NxTextField(
                      controller: _emailController,
                      label: 'Email address',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter a valid email address';
                        if (!value.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    NxTextField(
                      controller: _usernameController,
                      label: 'Full name',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: 14),
                    NxTextField(
                      controller: _shopNameController,
                      label: 'Shop name',
                      prefixIcon: Icons.storefront_rounded,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter a shop name' : null,
                    ),
                    const SizedBox(height: 14),
                    NxTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      validator: (v) => ((v?.trim().length ?? 0) < 6) ? 'Password must be at least 6 characters' : null,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: palette.textMuted),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 14),
                    NxTextField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      prefixIcon: Icons.lock_reset_rounded,
                      obscure: _obscureConfirm,
                      validator: (v) => (v?.trim() != _passwordController.text.trim()) ? 'Passwords do not match' : null,
                      suffix: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: palette.textMuted),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                        InkWell(
                          onTap: _generateCaptcha,
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
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 5, color: palette.primary),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.refresh_rounded, size: 18, color: palette.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    NxButton(
                      label: _isSubmitting ? 'Creating...' : 'Create account',
                      onPressed: _isSubmitting ? null : _createAccount,
                      height: 52,
                      expanded: true,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Already have an account? Sign in', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w600)),
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
