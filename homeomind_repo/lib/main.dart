// main.dart
// HomeoMind — high-contrast dark theme + simple router.
// FIX: previous version fed a light textTheme into darkTheme → black-on-black.
// Dark text styles are now derived from a dark Typography base.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/ui_case_detail.dart';
import 'ui/ui_dashboard.dart';
import 'ui/ui_doc_login.dart';
import 'ui/ui_patient_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HomeoMindApp());
}

class HomeoMindApp extends StatelessWidget {
  const HomeoMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF35C982); // brighter green reads well on dark
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    // CRITICAL: build text styles from a DARK base so colors are white/near-
    // white. GoogleFonts.interTextTheme() with no argument bakes in black.
    final darkText = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white).copyWith(
          headlineSmall: GoogleFonts.fraunces(
              fontWeight: FontWeight.w700, color: Colors.white),
          titleLarge: GoogleFonts.fraunces(
              fontWeight: FontWeight.w700, color: Colors.white),
          titleMedium: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: Colors.white),
        );

    return MaterialApp(
      title: 'HomeoMind',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // forced high-contrast dark, per requirement
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0E1512),
        textTheme: darkText,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: const Color(0xFF14201A),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.fraunces(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: const Color(0xFF17231C),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A3B31), width: 0.8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3B5245)),
          ),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF14201A),
          labelStyle: const TextStyle(color: Color(0xFFA9C4B4)),
          hintStyle: const TextStyle(color: Color(0xFF6E8578)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: seed,
            foregroundColor: const Color(0xFF06281A),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: seed,
          foregroundColor: const Color(0xFF06281A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2A3B31),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      // -------- Router --------
      initialRoute: '/',
      routes: {
        '/': (_) => const PatientHomeScreen(), // patient booking UI
        '/doc': (_) => const DocLoginScreen(), // doctor login (demo123)
        '/dashboard': (_) => const DashboardScreen(), // after login
        '/new-case': (_) => const CaseDetailScreen(),
      },
    );
  }
}
