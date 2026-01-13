import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TransactionType { credit, debit }

class ExpenseApiService {
  // REPLACE WITH YOUR NODE.JS BACKEND URL (e.g. from Render/Heroku)
  static const String baseUrl =
      "http://192.168.1.6:5000"; // LAN IP (Firewall Rule Verified)

  // Helper to get the Firebase JWT token
  static Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      // debugPrint('Error fetching auth token: $e');
      return null;
    }
  }

  // Generate unique expense ID
  static String generateExpenseId() {
    return const Uuid().v4();
  }

  // Add new expense/transaction
  static Future<Map<String, dynamic>> addExpense({
    required String title,
    required double amount,
    required String category,
    required String date,
    String description = '', // Optional description
    TransactionType type = TransactionType.debit, // Default to debit
  }) async {
    try {
      final token = await _getAuthToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final expenseId = generateExpenseId();

      final response = await http.post(
        Uri.parse('$baseUrl/addExpense'),
        headers: headers,
        body: jsonEncode({
          'expenseID': expenseId,
          'title': title,
          'amount': amount,
          'category': category,
          'description': description,
          'date': date,
          'type': type.name.toUpperCase(), // Send as CREDIT/DEBIT
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Transaction added successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add transaction: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get all expenses
  static Future<Map<String, dynamic>> getExpenses() async {
    try {
      final token = await _getAuthToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(
        Uri.parse('$baseUrl/getExpenses'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['expenses'] ?? []};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch expenses: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update expense
  static Future<Map<String, dynamic>> updateExpense({
    required String expenseId,
    required String date,
    String? title,
    double? amount,
    String? category,
    String? description,
    TransactionType? type,
  }) async {
    try {
      final token = await _getAuthToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final updateData = <String, dynamic>{
        'expenseID': expenseId,
        'date': date,
      };

      if (title != null) updateData['title'] = title;
      if (amount != null) updateData['amount'] = amount;
      if (category != null) updateData['category'] = category;
      if (description != null) updateData['description'] = description;
      if (type != null) updateData['type'] = type.name.toUpperCase();

      final response = await http.put(
        Uri.parse('$baseUrl/updateExpense'),
        headers: headers,
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete expense
  static Future<Map<String, dynamic>> deleteExpense({
    required String expenseId,
    required String date,
  }) async {
    try {
      final token = await _getAuthToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.delete(
        Uri.parse('$baseUrl/deleteExpense'),
        headers: headers,
        body: jsonEncode({'expenseID': expenseId, 'date': date}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Expense deleted successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete expense: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

// Expense model class (Renamed conceptually to Transaction but keeping class name to minimize refactor)
class Expense {
  final String expenseId;
  final String title;
  final double amount;
  final String category;
  final String description; // Original SMS or User Note
  final String date;
  final TransactionType type;

  Expense({
    required this.expenseId,
    required this.title,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    this.type = TransactionType.debit,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    TransactionType parseType(String? typeStr) {
      if (typeStr == null) return TransactionType.debit;
      if (typeStr.toUpperCase() == 'CREDIT') return TransactionType.credit;
      return TransactionType.debit;
    }

    return Expense(
      expenseId: json['expenseID'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      type: parseType(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseID': expenseId,
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
      'type': type.name.toUpperCase(),
    };
  }
}
