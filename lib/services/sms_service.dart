import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/api_integration.dart';
import 'package:flutter/material.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  final ExpenseProvider expenseProvider;

  SmsService(this.expenseProvider);

  /// Request permissions and Sync recent SMS
  Future<void> init() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        debugPrint("SMS Permission denied");
        return;
      }
    }

    await _syncMessages();
  }

  /// Reads last 100 SMS -> Filters for Bank Transactions -> Adds to Expense
  Future<void> _syncMessages() async {
    try {
      debugPrint("Syncing SMS...");
      List<SmsMessage> messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50, // Look at last 50 messages
      );

      debugPrint("Found ${messages.length} SMS");

      for (var message in messages) {
        _processMessage(message);
      }
    } catch (e) {
      debugPrint("Error syncing SMS: $e");
    }
  }

  void _processMessage(SmsMessage message) {
    String body = message.body ?? "";
    DateTime? date = message.date;

    // Skip if too old (e.g., older than 30 days) - Optional optimization
    if (date != null &&
        date.isBefore(DateTime.now().subtract(const Duration(days: 30)))) {
      return;
    }

    // Keyword check
    String lowerBody = body.toLowerCase();

    // Debit Keywords
    bool isDebit =
        lowerBody.contains("debited") ||
        lowerBody.contains("spent") ||
        lowerBody.contains("sent") ||
        lowerBody.contains("paid") ||
        lowerBody.contains("purchase") ||
        lowerBody.contains("withdrawn") ||
        lowerBody.contains("tran") || // Matches transaction, transfer
        lowerBody.contains("txn") ||
        lowerBody.contains("dr") ||
        childrenCheck(lowerBody, "paid to");

    // Credit Keywords
    bool isCredit =
        lowerBody.contains("credited") ||
        lowerBody.contains("received") ||
        lowerBody.contains("deposited");

    if (!isDebit && !isCredit) return;

    // Duplicate Check: Check if an expense with SAME amount and SAME date (approx) exists?
    // For simplicity in this version, we will just parse.
    // In a real app, you'd store the 'lastSyncedSmsId' locally.

    // Amount Extraction
    RegExp amountRegExp = RegExp(
      r"(?:₹|Rs[:.]?|INR)\s*(\d+(?:\.\d{1,2})?)",
      caseSensitive: false,
    );
    Match? amountMatch = amountRegExp.firstMatch(body);

    if (amountMatch != null) {
      String amountStr = amountMatch.group(1)!;
      double amount = double.tryParse(amountStr) ?? 0.0;

      // Filter out OTPs or spam containing numbers but not real transactions
      if (amount == 0) return;

      // Merchant/Title Extraction
      String merchant = "Bank Transaction";

      // Remove "Info:" prefix if present
      String cleanBody = body.replaceAll(
        RegExp(r"^Info:\s*", caseSensitive: false),
        "",
      );
      String lowerCleanBody = cleanBody.toLowerCase();

      if (isDebit) {
        if (lowerCleanBody.contains("to ")) {
          merchant = cleanBody
              .split(RegExp(r"to ", caseSensitive: false))
              .last
              .split(" ")
              .first;
        } else if (lowerCleanBody.contains("at ")) {
          merchant = cleanBody
              .split(RegExp(r"at ", caseSensitive: false))
              .last
              .split(" ")
              .first;
        } else if (lowerCleanBody.contains("by ")) {
          // Common in UPI: "by Mob Bk" or "by X"
          merchant = cleanBody
              .split(RegExp(r"by ", caseSensitive: false))
              .last
              .split(" ")
              .first;
        }
      } else {
        if (lowerCleanBody.contains("from ")) {
          merchant = cleanBody
              .split(RegExp(r"from ", caseSensitive: false))
              .last
              .split(" ")
              .first;
        } else if (lowerCleanBody.contains("by ")) {
          merchant = cleanBody
              .split(RegExp(r"by ", caseSensitive: false))
              .last
              .split(" ")
              .first;
        }
      }

      // Cleanup merchant name (remove punctuation)
      merchant = merchant.replaceAll(RegExp(r'[^\w\s]'), '');
      if (merchant.length > 20) {
        merchant = merchant.substring(0, 20); // Cap length
      }

      // Check if this expense already exists
      bool exists = expenseProvider.expenses.any((e) {
        try {
          DateTime eDate = DateTime.parse(e.date);
          return e.amount == amount &&
              eDate.year == date?.year &&
              eDate.month == date?.month &&
              eDate.day == date?.day;
        } catch (_) {
          return false;
        }
      });

      if (!exists) {
        expenseProvider.addExpense(
          title: merchant.isEmpty ? "Transaction" : merchant,
          amount: amount,
          category: isCredit ? "Income" : "UPI",
          description: body, // Store original SMS
          date: date?.toIso8601String() ?? DateTime.now().toIso8601String(),
          type: isCredit ? TransactionType.credit : TransactionType.debit,
        );
        debugPrint("Auto-added: $amount at $merchant");
      }
    }
  }

  bool childrenCheck(String text, String sub) => text.contains(sub);
}
