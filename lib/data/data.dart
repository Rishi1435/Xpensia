import 'package:flutter/material.dart';
import 'package:xpensia/data/api_integration.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  double _totalIncome = 20000.0; // Default income - you can make this dynamic

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalIncome => _totalIncome;

  // Get total expenses amount
  double get totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  // Get total balance (income - expenses)
  double get totalBalance => _totalIncome - totalExpenses;

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
        final dateOnly = DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
        
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
        final monthKey = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';
        
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + expense.amount;
      } catch (e) {
        // Skip invalid dates
        continue;
      }
    }
    
    return monthlyTotals;
  }

  // Update total income
  void updateTotalIncome(double newIncome) {
    _totalIncome = newIncome;
    notifyListeners();
  }

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
  }) async {
    try {
      final result = await ExpenseApiService.addExpense(
        title: title,
        amount: amount,
        category: category,
        date: date,
      );

      if (result['success']) {
        // Add to local list immediately for better UX
        final newExpense = Expense(
          expenseId: ExpenseApiService.generateExpenseId(),
          title: title,
          amount: amount,
          category: category,
          date: date,
        );
        _expenses.add(newExpense);
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
  }) async {
    try {
      final result = await ExpenseApiService.updateExpense(
        expenseId: expenseId,
        date: date,
        title: title,
        amount: amount,
        category: category,
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
            date: date,
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
          ? categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'None',
    };
  }
}