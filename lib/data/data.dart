import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpensia/data/api_integration.dart';
import 'package:xpensia/services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  // double _totalIncome = 20000.0; // Default income - removed

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // double get totalIncome => _totalIncome; // Removed in favor of dynamic calculation

  // Get total expenses amount (Debits)
  double get totalExpenses {
    return _expenses
        .where((e) => e.type == TransactionType.debit)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Get total income amount (Credits)
  double get totalIncome {
    // If you still want to support the manual base income override, you can add it here.
    // For now, we sum up all Credit transactions.
    return _expenses
        .where((e) => e.type == TransactionType.credit)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Get total balance (income - expenses)
  double get totalBalance => totalIncome - totalExpenses;

  // Get expenses by category
  Map<String, double> get expensesByCategory {
    Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  // Get recent expenses (last 10)
  List<Expense> get recentExpenses {
    var sortedExpenses = List<Expense>.from(_expenses);
    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
    return sortedExpenses.take(10).toList();
  }

  // Get daily expenses for the last 7 days
  Map<DateTime, double> get dailyExpenses {
    Map<DateTime, double> dailyTotals = {};
    final now = DateTime.now();

    // Initialize last 7 days with 0
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailyTotals[date] = 0;
    }

    // Calculate actual expenses
    for (var expense in _expenses) {
      try {
        final expenseDate = DateTime.parse(expense.date);
        final dateOnly = DateTime(
          expenseDate.year,
          expenseDate.month,
          expenseDate.day,
        );

        if (dailyTotals.containsKey(dateOnly)) {
          dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0) + expense.amount;
        }
      } catch (e) {
        // Skip invalid dates
        continue;
      }
    }

    return dailyTotals;
  }

  // Get monthly expenses
  Map<String, double> get monthlyExpenses {
    Map<String, double> monthlyTotals = {};

    for (var expense in _expenses) {
      try {
        final expenseDate = DateTime.parse(expense.date);
        final monthKey =
            '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

        monthlyTotals[monthKey] =
            (monthlyTotals[monthKey] ?? 0) + expense.amount;
      } catch (e) {
        // Skip invalid dates
        continue;
      }
    }

    return monthlyTotals;
  }

  // Update total income - Deprecated
  // void updateTotalIncome(double newIncome) {
  //   _totalIncome = newIncome;
  //   notifyListeners();
  // }

  // Load all expenses from API
  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ExpenseApiService.getExpenses();
      if (result['success']) {
        _expenses = (result['data'] as List)
            .map((json) => Expense.fromJson(json))
            .toList();

        // Sort by Date Descending (Newest First)
        _expenses.sort((a, b) => b.date.compareTo(a.date));

        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new expense
  Future<bool> addExpense({
    required String title,
    required double amount,
    required String category,
    required String date,
    String description = '',
    TransactionType type = TransactionType.debit,
  }) async {
    try {
      final result = await ExpenseApiService.addExpense(
        title: title,
        amount: amount,
        category: category,
        description: description,
        date: date,
        type: type,
      );

      if (result['success']) {
        // Add to local list immediately for better UX
        final newExpense = Expense(
          expenseId: ExpenseApiService.generateExpenseId(),
          title: title,
          amount: amount,
          category: category,
          description: description,
          date: date,
          type: type,
        );
        _expenses.add(newExpense);
        // Re-sort to ensure new item appears at top if it is recent
        _expenses.sort((a, b) => b.date.compareTo(a.date));

        // Check Budget Exceeded
        if (type == TransactionType.debit) {
          final budget = getBudgetForCategory(category);
          if (budget != null) {
            final totalSpent = getCategorySpending(category);
            if (totalSpent > budget.amount) {
              NotificationService().showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: 'Budget Alert ⚠️',
                body:
                    'You have exceeded your $category budget by ₹${(totalSpent - budget.amount).toStringAsFixed(0)}',
              );
            }
          }
        }

        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to add expense: $e';
      notifyListeners();
      return false;
    }
  }

  // Update expense
  Future<bool> updateExpense({
    required String expenseId,
    required String date,
    String? title,
    double? amount,
    String? category,
    String? description,
    TransactionType? type,
  }) async {
    try {
      final result = await ExpenseApiService.updateExpense(
        expenseId: expenseId,
        date: date,
        title: title,
        amount: amount,
        category: category,
        description: description,
        type: type,
      );

      if (result['success']) {
        // Update local list
        final index = _expenses.indexWhere((e) => e.expenseId == expenseId);
        if (index != -1) {
          _expenses[index] = Expense(
            expenseId: expenseId,
            title: title ?? _expenses[index].title,
            amount: amount ?? _expenses[index].amount,
            category: category ?? _expenses[index].category,
            description: description ?? _expenses[index].description,
            date: date,
            type: type ?? _expenses[index].type,
          );
          notifyListeners();
        }
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to update expense: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId, String date) async {
    try {
      final result = await ExpenseApiService.deleteExpense(
        expenseId: expenseId,
        date: date,
      );

      if (result['success']) {
        // Remove from local list
        _expenses.removeWhere((e) => e.expenseId == expenseId);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh expenses
  Future<void> refreshExpenses() async {
    await loadExpenses();
  }

  // Get expense statistics
  Map<String, dynamic> getExpenseStatistics() {
    if (_expenses.isEmpty) {
      return {
        'totalExpenses': 0.0,
        'averageExpense': 0.0,
        'highestExpense': 0.0,
        'lowestExpense': 0.0,
        'expenseCount': 0,
        'topCategory': 'None',
      };
    }

    final amounts = _expenses.map((e) => e.amount).toList();
    final categoryTotals = expensesByCategory;

    return {
      'totalExpenses': totalExpenses,
      'averageExpense': totalExpenses / _expenses.length,
      'highestExpense': amounts.reduce((a, b) => a > b ? a : b),
      'lowestExpense': amounts.reduce((a, b) => a < b ? a : b),
      'expenseCount': _expenses.length,
      'topCategory': categoryTotals.isNotEmpty
          ? categoryTotals.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
          : 'None',
    };
  }
  // --- Budgeting Logic ---

  final List<Budget> _budgets = [];
  List<Budget> get budgets => _budgets;

  // Set (Add or Update) a budget
  void setBudget(String category, double amount) {
    final index = _budgets.indexWhere((b) => b.category == category);
    if (index != -1) {
      _budgets[index] = Budget(
        id: _budgets[index].id,
        category: category,
        amount: amount,
      );
    } else {
      _budgets.add(
        Budget(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          category: category,
          amount: amount,
        ),
      );
    }
    notifyListeners();
  }

  // Delete a budget
  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // Get progress for a specific category
  double getCategorySpending(String category) {
    return _expenses
        .where((e) => e.category == category && e.type == TransactionType.debit)
        .fold(0, (sum, item) => sum + item.amount);
  }

  Budget? getBudgetForCategory(String category) {
    try {
      return _budgets.firstWhere((b) => b.category == category);
    } catch (_) {
      return null;
    }
  }

  // --- Category Logic ---
  final List<String> _categories = [
    "Food",
    "Transport",
    "Entertainment",
    "Bills",
    "Shopping",
    "Groceries",
  ];
  List<String> get categories => _categories;

  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      _categories.sort(); // Keep alphabetical
      notifyListeners();
    }
  }

  void deleteCategory(String category) {
    if (_categories.contains(category)) {
      _categories.remove(category);
      notifyListeners();
    }
  }

  // --- Recurring/Subscription Logic ---

  List<RecurringExpense> _subscriptions = [];
  List<RecurringExpense> get subscriptions => _subscriptions;

  Future<void> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subString = prefs.getString('subscriptions');
    if (subString != null) {
      final List<dynamic> jsonList = jsonDecode(subString);
      _subscriptions = jsonList
          .map((j) => RecurringExpense.fromJson(j))
          .toList();
    }
    notifyListeners();
  }

  Future<void> saveSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String subString = jsonEncode(
      _subscriptions.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('subscriptions', subString);
  }

  void addSubscription(RecurringExpense sub) {
    _subscriptions.add(sub);
    saveSubscriptions();
    notifyListeners();
  }

  void deleteSubscription(String id) {
    _subscriptions.removeWhere((s) => s.id == id);
    saveSubscriptions();
    notifyListeners();
  }

  // call this on app init
  Future<void> checkRecurringExpenses() async {
    await loadSubscriptions();
    final now = DateTime.now();
    bool changed = false;

    for (var sub in _subscriptions) {
      if (!sub.isActive) continue;

      // while nextDueDate is today or in the past
      while (sub.nextDueDate.isBefore(now) || isSameDay(sub.nextDueDate, now)) {
        // Add Expense
        await addExpense(
          title: sub.title,
          amount: sub.amount,
          category: sub.category,
          date: DateFormat(
            'yyyy-MM-dd',
          ).format(sub.nextDueDate), // Use due date as expense date
          description: 'Auto-generated subscription',
          type: TransactionType.debit,
        );

        NotificationService().showNotification(
          id: sub.nextDueDate.millisecondsSinceEpoch ~/ 1000,
          title: 'Subscription Paid 🔄',
          body: 'Auto-logged ${sub.title} (₹${sub.amount.toStringAsFixed(0)})',
        );

        // Update Next Due Date
        if (sub.interval == 'Monthly') {
          sub.nextDueDate = DateTime(
            sub.nextDueDate.year,
            sub.nextDueDate.month + 1,
            sub.nextDueDate.day,
          );
        } else if (sub.interval == 'Weekly') {
          sub.nextDueDate = sub.nextDueDate.add(const Duration(days: 7));
        } else if (sub.interval == 'Yearly') {
          sub.nextDueDate = DateTime(
            sub.nextDueDate.year + 1,
            sub.nextDueDate.month,
            sub.nextDueDate.day,
          );
        }

        changed = true;
      }
    }

    if (changed) {
      await saveSubscriptions();
      notifyListeners();
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class RecurringExpense {
  final String id;
  final String title;
  final double amount;
  final String category;
  DateTime nextDueDate;
  final String interval; // 'Weekly', 'Monthly', 'Yearly'
  bool isActive;

  RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.nextDueDate,
    required this.interval,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'nextDueDate': nextDueDate.toIso8601String(),
      'interval': interval,
      'isActive': isActive,
    };
  }

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      category: json['category'],
      nextDueDate: DateTime.parse(json['nextDueDate']),
      interval: json['interval'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class Budget {
  final String id;
  final String category;
  final double amount;

  Budget({required this.id, required this.category, required this.amount});
}
