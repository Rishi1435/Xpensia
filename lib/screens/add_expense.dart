import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/api_integration.dart';

class Addexpense extends StatefulWidget {
  const Addexpense({super.key});

  @override
  State<Addexpense> createState() => _AddexpenseState();
}

class _AddexpenseState extends State<Addexpense> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.debit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat("dd/MM/yyyy").format(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _expenseController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    setState(() {
      _categoryController.text = category;
    });
    Navigator.of(context).pop();
  }

  Future<void> _saveExpense() async {
    // Validate inputs
    if (_titleController.text.isEmpty) {
      _showSnackBar('Please enter a title', Colors.red);
      return;
    }
    if (_expenseController.text.isEmpty) {
      _showSnackBar('Please enter an amount', Colors.red);
      return;
    }
    if (_categoryController.text.isEmpty) {
      _showSnackBar('Please select a category', Colors.red);
      return;
    }

    double? amount = double.tryParse(_expenseController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final result = await ExpenseApiService.addExpense(
        title: _titleController.text.trim(),
        amount: amount,
        category: _categoryController.text,
        date: formattedDate,
        type: _selectedType,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSnackBar('Expense added successfully!', Colors.green);
        _clearForm();
        // Navigate back to home screen
        if (mounted) Navigator.of(context).pop();
      } else {
        _showSnackBar(result['message'], Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _categoryController.clear();
    _expenseController.clear();
    _dateController.text = DateFormat("dd/MM/yyyy").format(DateTime.now());
    selectedDate = DateTime.now();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Add Expenses",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Transaction Type Toggle
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeButton("Expense", TransactionType.debit),
                    _buildTypeButton("Income", TransactionType.credit),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextFormField(
                  controller: _expenseController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    labelText: "Amount",
                    hintText: "Enter the expense amount",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    fillColor: Theme.of(context).colorScheme.tertiary,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    labelText: "Title",
                    hintText: "Enter expense title",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.title),
                    fillColor: Theme.of(context).colorScheme.tertiary,
                    filled: true,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    labelText: "Category",
                    hintText: "Select the Category",
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Theme.of(context).colorScheme.tertiary,
                    filled: true,
                    prefixIcon: const Icon(Icons.view_list_rounded),
                    suffixIcon: Builder(
                      builder: (context) => GestureDetector(
                        onTap: () {
                          showPopover(
                            context: context,
                            bodyBuilder: (context) =>
                                MenuList(onSelect: _selectCategory),
                            direction: PopoverDirection.left,
                            width: 200,
                            height: 180,
                            backgroundColor: isDark
                                ? Colors.grey[850]!
                                : Colors.white,
                          );
                        },
                        child: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    labelText: "Date",
                    hintText: "Select the Date",
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Theme.of(context).colorScheme.tertiary,
                    filled: true,
                    prefixIcon: const Icon(Icons.date_range_outlined),
                    suffixIcon: Builder(
                      builder: (context) => GestureDetector(
                        onTap: () async {
                          DateTime? newDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.utc(2010),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: isDark
                                      ? const ColorScheme.dark(
                                          primary: Colors.tealAccent,
                                          onPrimary: Colors.black,
                                          surface: Color(0xFF1E1E1E),
                                          onSurface: Colors.white,
                                        )
                                      : const ColorScheme.light(
                                          primary: Colors.deepPurple,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (newDate != null) {
                            setState(() {
                              _dateController.text = DateFormat(
                                "dd/MM/yyyy",
                              ).format(newDate);
                              selectedDate = newDate;
                            });
                          }
                        },
                        child: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, TransactionType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class MenuList extends StatelessWidget {
  final void Function(String) onSelect;
  const MenuList({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final categories = context.select<ExpenseProvider, List<String>>(
      (p) => p.categories,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(categories[index]),
          onTap: () => onSelect(categories[index]),
        );
      },
    );
  }
}
