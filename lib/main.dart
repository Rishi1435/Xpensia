import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/theme_provider.dart';
import 'package:xpensia/screens/home/home_screen.dart';
import 'package:xpensia/screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xpensia/screens/splash_screen.dart';
import 'package:xpensia/screens/biometric_wrapper.dart';
import 'package:xpensia/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(); // Initialize Firebase
  await NotificationService().init(); // Initialize Notifications
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          themeMode: themeProvider.themeMode,
          // Dark Theme (Royal Blue / Midnight)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            textTheme: TextTheme(
              bodyMedium: GoogleFonts.dmSans(color: Colors.white),
              bodyLarge: GoogleFonts.dmSans(color: Colors.white),
            ),
            scaffoldBackgroundColor: Colors.black,
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF0074E4), // Royal Blue (Visible)
              secondary: Colors.blueAccent, // Lighter Cyan-Blue
              tertiary: const Color(0xFF1A1A1A), // Dark Grey
              onPrimary: Colors.white,
              surface: Colors.black,
              outline: Colors.white54,
            ),
          ),
          // Light Theme (Clean White / Royal Blue)
          theme: ThemeData(
            brightness: Brightness.light,
            textTheme: TextTheme(
              bodyMedium: GoogleFonts.dmSans(color: Colors.black),
              bodyLarge: GoogleFonts.dmSans(color: Colors.black),
            ),
            colorScheme: ColorScheme.light(
              surface: Colors.white,
              onSurface: Colors.black,
              primary: const Color(0xFF000428), // Midnight Blue
              secondary: const Color(0xFF0074E4), // Royal Blue
              tertiary: const Color(0xFFF0F0F0),
              outline: Colors.grey,
              onPrimary: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const BiometricWrapper(
            child: HomeScreen(),
          ); // User is signed in
        }
        return const Login(); // User is signed out
      },
    );
  }
}
