import 'package:attendec/Authentication/login.dart';
import 'package:attendec/pages/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  runApp(
      ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const MyApp(),
      ));
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // use .playIntegrity for release
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,

        // ── Dark theme ──────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12121F),
        cardColor: const Color(0xFF1E1E30),
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF3D7BFF),
          secondary: Color(0xFF2DD4A0),
          surface:   Color(0xFF1E1E30),
          background: Color(0xFF12121F),
          onBackground: Color(0xFFFFFFFF),
          onSurface: Color(0xFFFFFFFF),
        ),
      ),

        // ── Light theme ─────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F2FF),
        cardColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary:   Color(0xFF3D7BFF),
          secondary: Color(0xFF2DD4A0),
          surface:   Color(0xFFFFFFFF),
          background: Color(0xFFF0F2FF),
          onBackground: Color(0xFF1A1A2E),
          onSurface: Color(0xFF1A1A2E),
        ),
      ),

      home:  LoginPage(),
    );
  }
}
