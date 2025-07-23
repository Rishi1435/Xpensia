import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ExpenseApiService {
  static const String baseUrl = 'https://3urw9s7l8k.execute-api.us-east-1.amazonaws.com';
  
  // Generate unique expense ID
  static String generateExpenseId() {
    return const Uuid().v4();
  }

  // Add new expense
  static Future<Map<String, dynamic>> addExpense({
    required String title,
    required double amount,
    required String category,
    required String date,
  }) async {
    try {
      final expenseId = generateExpenseId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/addExpense'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'expenseID': expenseId,
          'title': title,
          'amount': amount,
          'category': category,
          'date': date,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Expense added successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add expense: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all expenses
  static Future<Map<String, dynamic>> getExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getExpenses'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['expenses'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch expenses: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update expense
  static Future<Map<String, dynamic>> updateExpense({
    required String expenseId,
    required String date,
    String? title,
    double? amount,
    String? category,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'expenseID': expenseId,
        'date': date,
      };

      if (title != null) updateData['title'] = title;
      if (amount != null) updateData['amount'] = amount;
      if (category != null) updateData['category'] = category;

      final response = await http.put(
        Uri.parse('$baseUrl/updateExpense'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Expense updated successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update expense: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete expense
  static Future<Map<String, dynamic>> deleteExpense({
    required String expenseId,
    required String date,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/deleteExpense'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'expenseID': expenseId,
          'date': date,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Expense deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete expense: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}

// Expense model class
class Expense {
  final String expenseId;
  final String title;
  final double amount;
  final String category;
  final String date;

  Expense({
    required this.expenseId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expenseID'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseID': expenseId,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date,
    };
  }
}