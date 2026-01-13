import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/api_integration.dart';
import 'package:xpensia/data/data.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final Expense expense;

  const TransactionDetailsScreen({super.key, required this.expense});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _amountController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _categoryController = TextEditingController(text: widget.expense.category);
    _amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final deletedExpense = widget.expense;

    // Optimistic Delete
    // Note: We need to implement a 'restore' or 'add' back if undo is pressed.
    // For now, we will just hold the data and re-add if undo is triggered.
    // But since the provider deletes it from state, we need to be careful.

    // We will wait for the delete API confirmation before showing the snackbar
    // to keep it simple, or implement a proper UNDO pattern.
    // The user requirement says "undo to undo the delete".

    // Pattern:
    // 1. Show confirmation dialog? (Maybe skip for speed)
    // 2. Call Delete API.
    // 3. If success, pop screen, show SnackBar in previous screen with Undo.

    final success = await provider.deleteExpense(
      deletedExpense.expenseId,
      deletedExpense.date,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context); // Go back to list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Transaction deleted"),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              // Re-add the expense
              provider.addExpense(
                title: deletedExpense.title,
                amount: deletedExpense.amount,
                category: deletedExpense.category,
                date: deletedExpense.date,
                description: deletedExpense.description,
                type: deletedExpense.type,
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete transaction")));
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;

    final provider = context.read<ExpenseProvider>();
    final amount =
        double.tryParse(_amountController.text) ?? widget.expense.amount;

    final success = await provider.updateExpense(
      expenseId: widget.expense.expenseId,
      date: widget.expense.date,
      title: _titleController.text,
      category: _categoryController.text,
      amount: amount,
      // description: widget.expense.description, // Keep description as is
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Changes saved")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.expense.type == TransactionType.credit;

    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? CupertinoIcons.check_mark : CupertinoIcons.pencil,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.delete, color: Colors.redAccent),
            onPressed: () => _deleteTransaction(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount & Icon Center Display
            Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCredit
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      isCredit
                          ? CupertinoIcons.arrow_down
                          : CupertinoIcons.arrow_up,
                      color: isCredit ? Colors.green : Colors.redAccent,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 20),
                  _isEditing
                      ? TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Amount",
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixText: "₹",
                            prefixStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          "₹${widget.expense.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  SizedBox(height: 10),
                  Text(
                    _formatDate(widget.expense.date),
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            // Details Form
            _buildDetailRow(
              "Title",
              _titleController,
              CupertinoIcons.textbox,
              enabled: _isEditing,
            ),
            SizedBox(height: 20),
            _buildDetailRow(
              "Category",
              _categoryController,
              CupertinoIcons.tag,
              enabled: _isEditing,
            ),
            SizedBox(height: 20),

            // Description (Read Only usually, unless we want to edit notes)
            if (widget.expense.description.isNotEmpty) ...[
              Text(
                "Original Message / Details",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Text(
                  widget.expense.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: enabled ? Colors.blueAccent : Colors.grey[800]!,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
