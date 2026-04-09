import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const RoomExpensesApp());
}

class RoomExpensesApp extends StatelessWidget {
  const RoomExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Expenses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1e293b),
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e293b),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
