
// import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xpensia/data/data.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/screens/home/home_screen.dart';
// import 'package:xpensia/screens/settings.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child:MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: TextTheme(bodyMedium: GoogleFonts.coda(color: Colors.white),bodyLarge: GoogleFonts.coda(color: Colors.white)),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF00458e),
          secondary: Color(0xFF000328),
          tertiary: Color(0xFF2B2B2B),
          onPrimary: Colors.white,
          surface: Colors.black
        ),
      ),
       theme: ThemeData( 
        brightness: Brightness.light,  
        textTheme: TextTheme(bodyMedium: GoogleFonts.coda(color: Colors.black),bodyLarge: GoogleFonts.coda(color: Colors.black)),
        colorScheme: ColorScheme.light(
          surface: Colors.white,
          onSurface: Colors.black,
          primary: Color(0xFF08203e),
          secondary: Color(0xFF557c93),
          tertiary: const Color.fromARGB(255, 218, 243, 254),
          outline: Colors.grey,
          onPrimary: Colors.black
        ),
        
      ),
      themeMode: ThemeMode.system
    );
  }
}


