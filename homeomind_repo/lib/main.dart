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
    // 1. Defining a professional, unified color palette
    const primaryGreen = Color(0xFF1D4D34);
    const softBackground = Color(0xFFF7FAF7);
    const darkText = Color(0xFF182D20);

    return MaterialApp(
      title: 'HomeoMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: softBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          surface: Colors.white,
        ),
        // 2. Refined Typography for a premium look
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displaySmall: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          bodyMedium: const TextStyle(fontSize: 15, color: Color(0xFF4A554A)),
        ),
        // 3. Modern, flat component design
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE0E6DE), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F4F0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: primaryGreen,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const PatientHomeScreen(),
        '/doc': (_) => const DocLoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/new-case': (_) => const CaseDetailScreen(),
      },
    );
  }
}
