import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'ui/views/auth_view.dart';

void main() {
  runApp(const ProviderScope(child: AdminDashboardApp()));
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gilhari Admin Dashboard',
      theme: AppTheme.darkTheme,
      home: const AuthView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
