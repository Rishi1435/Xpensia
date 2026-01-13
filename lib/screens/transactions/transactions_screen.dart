import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/api_integration.dart';
import 'package:xpensia/services/import_export_service.dart';
import 'package:xpensia/screens/transactions/transaction_details_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Filter State
  TransactionType? _selectedType;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  // Sorting State
  final bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    // Ensure data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  // Filter Logic
  List<Expense> _getFilteredExpenses(List<Expense> allExpenses) {
    return allExpenses.where((expense) {
      // Filter by Type
      if (_selectedType != null && expense.type != _selectedType) {
        return false;
      }

      // Filter by Category
      if (_selectedCategory != null && expense.category != _selectedCategory) {
        return false;
      }

      // Filter by Date Range
      if (_startDate != null || _endDate != null) {
        try {
          final expenseDate = DateTime.parse(expense.date);
          if (_startDate != null && expenseDate.isBefore(_startDate!)) {
            return false;
          }
          if (_endDate != null) {
            // Add 1 day to end date to make it inclusive (end of day)
            final endOfDay = _endDate!
                .add(const Duration(days: 1))
                .subtract(const Duration(seconds: 1));
            if (expenseDate.isAfter(endOfDay)) {
              return false;
            }
          }
        } catch (e) {
          return false; // Invalid date
        }
      }

      return true;
    }).toList()..sort((a, b) {
      // Sort by Date
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  // UI Helpers
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Filter Transactions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Filter
                  const Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<TransactionType?>(
                    isExpanded: true,
                    value: _selectedType,
                    hint: const Text('All Types'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      const DropdownMenuItem(
                        value: TransactionType.credit,
                        child: Text('Income (Credit)'),
                      ),
                      const DropdownMenuItem(
                        value: TransactionType.debit,
                        child: Text('Expense (Debit)'),
                      ),
                    ],
                    onChanged: (val) =>
                        setStateDialog(() => _selectedType = val),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<List<String>>(
                    // Get unique categories from provider
                    future: Future.value(
                      context
                          .read<ExpenseProvider>()
                          .expenses
                          .map((e) => e.category)
                          .toSet()
                          .toList()
                        ..sort(),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return DropdownButton<String?>(
                        isExpanded: true,
                        value: _selectedCategory,
                        hint: const Text('All Categories'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...snapshot.data!.map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          ),
                        ],
                        onChanged: (val) =>
                            setStateDialog(() => _selectedCategory = val),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Range
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() => _startDate = picked);
                            }
                          },
                          child: Text(
                            _startDate == null
                                ? 'Start Date'
                                : DateFormat('MM/dd/yyyy').format(_startDate!),
                          ),
                        ),
                      ),
                      const Text('-'),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: _startDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() => _endDate = picked);
                            }
                          },
                          child: Text(
                            _endDate == null
                                ? 'End Date'
                                : DateFormat('MM/dd/yyyy').format(_endDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Clear filters
                  setStateDialog(() {
                    _selectedType = null;
                    _selectedCategory = null;
                    _startDate = null;
                    _endDate = null;
                  });
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filters (parent state update)
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleDownload(List<Expense> expenses) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Generating PDF...")));

      await ImportExportService().generateAnddownloadPdfReport(
        expenses,
        startDate: _startDate,
        endDate: _endDate ?? DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
          Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              final displayedExpenses = _getFilteredExpenses(provider.expenses);
              return IconButton(
                icon: const Icon(Icons.download),
                onPressed: displayedExpenses.isEmpty
                    ? null
                    : () => _handleDownload(displayedExpenses),
                tooltip: 'Download Statement',
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (expenseProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${expenseProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => expenseProvider.refreshExpenses(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final displayedExpenses = _getFilteredExpenses(
            expenseProvider.expenses,
          );

          if (displayedExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No transactions found.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  if (_selectedType != null ||
                      _selectedCategory != null ||
                      _startDate != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = null;
                          _selectedCategory = null;
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter Summary Chips
              if (_selectedType != null ||
                  _selectedCategory != null ||
                  _startDate != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (_selectedType != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              _selectedType == TransactionType.credit
                                  ? 'Income'
                                  : 'Expense',
                            ),
                            onDeleted: () =>
                                setState(() => _selectedType = null),
                          ),
                        ),
                      if (_selectedCategory != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(_selectedCategory!),
                            onDeleted: () =>
                                setState(() => _selectedCategory = null),
                          ),
                        ),
                      if (_startDate != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              '${DateFormat('MM/dd').format(_startDate!)} - ${_endDate != null ? DateFormat('MM/dd').format(_endDate!) : 'Now'}',
                            ),
                            onDeleted: () => setState(() {
                              _startDate = null;
                              _endDate = null;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  itemCount: displayedExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = displayedExpenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TransactionDetailsScreen(expense: expense),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
