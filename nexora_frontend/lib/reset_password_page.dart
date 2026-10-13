import 'package:flutter/material.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      nxSnack(context, 'Please enter a valid email address', isError: true);
      return;
    }

    // Simulate sending reset link
    nxSnack(context, 'Reset link sent to $email (demo)');

    // Navigate back to login after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        leading: const NxBackButton(),
        title: const Text('Reset password'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
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
                      const NxIconBlock(icon: Icons.mark_email_read_rounded, color: Color(0xFF3B9DDB)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Forgot your password?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                            Text('We will send you a reset link', style: TextStyle(fontSize: 13, color: palette.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  NxTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'you@gmail.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  NxButton(label: 'Send reset link', onPressed: _sendResetLink, height: 50, expanded: true),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Back to sign in', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
