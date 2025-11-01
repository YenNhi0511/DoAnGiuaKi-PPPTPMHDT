// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'providers/activity_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home.dart';
import 'screens/student_home.dart';
import 'screens/register_screen.dart';
import 'screens/admin_manage_activities.dart';
import 'screens/setting_screen.dart';
import 'screens/activity_list_screen.dart';
import 'screens/history_screen.dart';
import 'screens/admin_report_screen.dart'; // ← THÊM
import 'screens/student_info_screen.dart'; // ← THÊM

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Quản lý Hoạt động SV',
          // --- ÁP DỤNG THEME TÙY CHỈNH ---
          theme: MyThemes.lightTheme,
          darkTheme: MyThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,

          // Điều hướng chính của ứng dụng
          home: Consumer<AuthService>(
            builder: (context, authService, _) {
              final userRole = authService.currentUser?.role;

              if (authService.isAuthLoading) {
                return const SplashScreen();
              }

              if (authService.isAuthenticated) {
                if (userRole == 'admin') {
                  return const AdminHomeScreen();
                } else {
                  return const StudentHomeScreen();
                }
              }

              return const LoginScreen();
            },
          ),

          // Định nghĩa routes
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/admin_home': (context) => const AdminHomeScreen(),
            '/student_home': (context) => const StudentHomeScreen(),
            '/admin_manage_activities': (context) =>
                const AdminManageActivitiesScreen(),
            '/settings': (context) => const SettingScreen(),
            '/activity_list': (context) => const ActivityListScreen(),
            '/history': (context) => const HistoryScreen(),
            '/admin_report': (context) => const AdminReportScreen(), // ← THÊM
            '/student_info': (context) => const StudentInfoScreen(), // ← THÊM
          },
        );
      },
    );
  }
}
