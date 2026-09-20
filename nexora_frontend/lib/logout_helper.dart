import 'package:flutter/material.dart';

import 'login_page.dart';
import 'services/api_service.dart';

/// Clears the session (backend + local tokens) and returns to the login page.
///
/// IMPORTANT: always call this with the CURRENT page's own context — a context
/// that is still mounted. Passing a context from a page that already navigated
/// away (e.g. the login page right after login) silently does nothing, because
/// that widget is disposed and its context can no longer navigate.
Future<void> performLogout(BuildContext context) async {
  await ApiService.logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}
