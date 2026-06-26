import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/file_manager_screen.dart';
import 'screens/asar_tools_screen.dart';
import 'screens/splash_screen_manager.dart';
import 'screens/language_installer_screen.dart';
import 'screens/api_keys_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/updater_screen.dart';
import 'screens/manager_screen.dart';

class GraystoneApp extends StatelessWidget {
  const GraystoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graystone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFF38BDF8),
          surface: const Color(0xFF111827),
          onSurface: const Color(0xFFE2E8F0),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF1E2D45)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E2D45)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E2D45)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          hintStyle: const TextStyle(color: Color(0xFF475569)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
        ),
        fontFamily: 'Segoe UI',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
          bodySmall: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/files': (context) => const FileManagerScreen(),
        '/asar': (context) => const AsarToolsScreen(),
        '/splash': (context) => const SplashScreenManager(),
        '/languages': (context) => const LanguageInstallerScreen(),
        '/apikeys': (context) => const ApiKeysScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/updater': (context) => const UpdaterScreen(),
        '/manager': (context) => const ManagerScreen(),
      },
    );
  }
}
