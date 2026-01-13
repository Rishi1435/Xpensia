import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:xpensia/screens/add_expense.dart';
import 'package:xpensia/screens/home/main_screen.dart';
import 'package:xpensia/screens/stat/stat_screen.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/services/sms_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 1. Load Expenses First
    final provider = context
        .read<ExpenseProvider>(); // Use read in initState/callback
    // Defer to next frame to allow build context access or just await directly if possible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await provider.loadExpenses();
      await provider.checkRecurringExpenses(); // Check Subscriptions

      // 2. Only after expenses are loaded, sync SMS
      if (mounted) {
        final smsService = SmsService(provider);
        await smsService.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(50),
          child: GNav(
            activeColor: Theme.of(
              context,
            ).colorScheme.secondary, // Royal Blue Text/Icon
            tabBackgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3), // Subtle Highlight
            gap: 8,
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.transparent,
            haptic: true,
            duration: Duration(milliseconds: 350),
            onTabChange: (value) {
              setState(() {
                index = value;
              });
            },
            tabs: [
              GButton(icon: CupertinoIcons.home, text: "Home"),
              GButton(icon: CupertinoIcons.graph_square, text: "Analysis"),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Addexpense();
              },
            ),
          );
        },
        shape: CircleBorder(),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              transform: const GradientRotation(pi / 4),
            ),
          ),
          child: Icon(CupertinoIcons.add, color: Colors.white),
        ),
      ),
      body: index == 0 ? MainScreen() : StatScreen(),
    );
  }
}
