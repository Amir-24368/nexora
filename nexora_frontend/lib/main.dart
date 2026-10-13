import 'package:flutter/material.dart';
import 'login_page.dart';
import 'services/api_service.dart';
import 'ui/theme.dart';

void main() {
  runApp(const NxApp());
}

/// Root widget: applies the Nexora light/dark Material themes and rebuilds
/// everything when the user cycles the theme mode.
class NxApp extends StatelessWidget {
  const NxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: nxThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nexora',
          theme: _buildTheme(NxTheme.light),
          darkTheme: _buildTheme(NxTheme.dark),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }

  /// Shared Material 3 theme: Inter everywhere, Nexora palettes for widgets
  /// that still come from Material under the hood (dialogs, menus, bottom
  /// nav), no default tinting/splash noise.
  ThemeData _buildTheme(NxTheme p) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: 'Inter',
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: p.textOnAccent,
        secondary: p.info,
        onSecondary: p.textOnAccent,
        error: p.danger,
        onError: p.textOnAccent,
        surface: p.surface,
        onSurface: p.textPrimary,
        surfaceContainerHighest: p.surfaceAlt,
        onSurfaceVariant: p.textMuted,
        outline: p.border,
        outlineVariant: p.border,
      ),
      scaffoldBackgroundColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.textPrimary,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary, fontFamily: 'Inter'),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: p.border)),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: p.primary, selectionColor: p.primary.withOpacity(0.25), selectionHandleColor: p.primary),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 15, color: p.textPrimary, fontFamily: 'Inter'),
      ),
    );
    // Inter needs explicit weights registered on TextTheme for M3 roles.
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: p.textPrimary, displayColor: p.textPrimary),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rise;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _rise = Tween<double>(begin: 18, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final palette = NxTheme.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, _rise.value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: nxHeroGradient),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Color(0x554F46E5), blurRadius: 32, offset: Offset(0, 12))],
                      ),
                      child: Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: palette.textOnAccent,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Nexora',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Retail operating system',
                      style: TextStyle(fontSize: 14, color: palette.textMuted, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 44),
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _fade.value,
                          minHeight: 5,
                          backgroundColor: palette.surfaceAlt,
                          color: palette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
