import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/api_integration.dart';
import 'package:intl/intl.dart';
import 'package:xpensia/screens/settings.dart';
import 'dart:io';
import 'package:xpensia/data/theme_provider.dart';
import 'package:xpensia/screens/transactions/transactions_screen.dart';
import 'package:xpensia/screens/transactions/transaction_details_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userInfo();
      // Auto-refresh handled by HomeScreen parent now
    });
  }

  void _userInfo() {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                                image: themeProvider.profileImagePath != null
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(themeProvider.profileImagePath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: themeProvider.profileImagePath == null
                                  ? Icon(
                                      CupertinoIcons.person_fill,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    )
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome..!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Text(
                          FirebaseAuth.instance.currentUser?.displayName ??
                              FirebaseAuth.instance.currentUser?.email?.split(
                                '@',
                              )[0] ??
                              'User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Settings()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),

            Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                double totalExpenses = expenseProvider.totalExpenses;
                double totalIncome = expenseProvider.totalIncome;
                double totalBalance = totalIncome - totalExpenses;

                return Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF000428), // Midnight Blue (Restored)
                        Color(0xFF0074E4), // Royal Blue
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black54
                            : Colors.white38,
                        offset: Offset(5, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Total Balance: ",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '₹${totalBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Container(
                                  height: 25,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white30,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.arrow_down,
                                    size: 14,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Income:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      '₹${totalIncome.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Container(
                                  height: 25,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white30,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.arrow_up,
                                    size: 14,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Expenses:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      '₹${totalExpenses.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transaction",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "View all",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Consumer<ExpenseProvider>(
                builder: (context, expenseProvider, child) {
                  if (expenseProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (expenseProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${expenseProvider.error}',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => expenseProvider.refreshExpenses(),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (expenseProvider.recentExpenses.isEmpty) {
                    return Center(
                      child: Text(
                        'No expenses yet.\nAdd your first expense!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    );
                  }

                  // Drag Down to Refresh
                  return RefreshIndicator(
                    onRefresh: () async {
                      await expenseProvider.loadExpenses();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: expenseProvider.recentExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenseProvider.recentExpenses[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TransactionDetailsScreen(
                                        expense: expense,
                                      ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Icon(
                                _getCategoryIcon(expense.category),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              expense.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${expense.category} • ${_formatDate(expense.date)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            trailing: Text(
                              '${expense.type == TransactionType.credit ? '+' : '-'}₹${expense.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: expense.type == TransactionType.credit
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return CupertinoIcons.table;
      case 'transport':
        return CupertinoIcons.car;
      case 'entertainment':
        return CupertinoIcons.game_controller;
      case 'bills':
        return CupertinoIcons.doc_text;
      case 'shopping':
        return CupertinoIcons.shopping_cart;
      case 'groceries':
        return CupertinoIcons.bag;
      default:
        return CupertinoIcons.money_dollar;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
