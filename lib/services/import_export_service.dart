import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart'; // Or open_file_plus
import 'package:intl/intl.dart';
import 'package:xpensia/data/api_integration.dart'; // For TransactionType and Expense model

class ImportExportService {
  // --- Import ---

  Future<List<Map<String, dynamic>>> pickAndParseCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final input = file.openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();

        // Assuming first row is header.
        // Basic mapping: Look for columns like "Date", "Amount", "Description/Title", "Type"
        if (fields.isEmpty) return [];

        final header = fields.first
            .map((e) => e.toString().toLowerCase())
            .toList();
        final data = fields.skip(1).toList();

        List<Map<String, dynamic>> parsedTransactions = [];

        int dateIdx = header.indexWhere((h) => h.contains('date'));
        int titleIdx = header.indexWhere(
          (h) =>
              h.contains('description') ||
              h.contains('title') ||
              h.contains('remarks'),
        );
        int amountIdx = header.indexWhere((h) => h.contains('amount'));
        int typeIdx = header.indexWhere(
          (h) => h.contains('type') || h.contains('cr/dr'),
        );

        // Fallbacks
        if (dateIdx == -1) dateIdx = 0;
        if (titleIdx == -1) titleIdx = 1;
        if (amountIdx == -1) amountIdx = 2;

        for (var row in data) {
          try {
            String date = row[dateIdx].toString();
            String title = row[titleIdx].toString();
            double amount =
                double.tryParse(
                  row[amountIdx].toString().replaceAll(',', ''),
                ) ??
                0.0;

            TransactionType type = TransactionType.debit;
            if (typeIdx != -1) {
              final rangeVal = row[typeIdx].toString().toLowerCase();
              if (rangeVal.contains('cr') ||
                  rangeVal.contains('credit') ||
                  rangeVal.contains('income')) {
                type = TransactionType.credit;
              }
            }

            // Auto-format date if possible (assuming YYYY-MM-DD for simplicity, else keep as is)
            // In real app, need robust date parsing

            parsedTransactions.add({
              'title': title,
              'amount': amount,
              'date': date,
              'type': type,
              'category': 'Imported', // Default category
            });
          } catch (e) {
            debugPrint('Error parsing row: $e');
          }
        }
        return parsedTransactions;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return [];
  }

  // --- Export ---

  Future<void> generateAnddownloadPdfReport(
    List<Expense> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Filter by date if needed
    final filtered = transactions.where((t) {
      if (startDate == null || endDate == null) return true;
      try {
        final d = DateTime.parse(t.date);
        // Fix: Use !isBefore to include startDate (inclusive start)
        return !d.isBefore(startDate) &&
            d.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return true;
      }
    }).toList();

    double totalCredit = filtered
        .where((t) => t.type == TransactionType.credit)
        .fold(0, (sum, t) => sum + t.amount);
    double totalDebit = filtered
        .where((t) => t.type == TransactionType.debit)
        .fold(0, (sum, t) => sum + t.amount);
    double balance = totalCredit - totalDebit;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Xpensia Statement',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total Income'),
                      pw.Text(
                        totalCredit.toStringAsFixed(2),
                        style: pw.TextStyle(color: PdfColors.green),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Total Expense'),
                      pw.Text(
                        totalDebit.toStringAsFixed(2),
                        style: pw.TextStyle(color: PdfColors.red),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Balance'),
                      pw.Text(balance.toStringAsFixed(2)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Table
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Title', 'Category', 'Type', 'Amount'],
              data: filtered.map((e) {
                // Shorten date to YYYY-MM-DD
                String dateStr = e.date;
                try {
                  dateStr = DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(e.date));
                } catch (_) {}

                return [
                  dateStr,
                  e.title,
                  e.category,
                  e.type.name.toUpperCase(),
                  e.amount.toStringAsFixed(2),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/statement.pdf');
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);
  }
}
