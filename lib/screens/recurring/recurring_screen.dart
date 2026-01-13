import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/api_integration.dart';
import 'package:xpensia/data/data.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions'), centerTitle: true),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final subs = provider.subscriptions;

          if (subs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.autorenew,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No subscriptions yet.\nAdd fixed expenses like Netflix or Rent.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final sub = subs[index];
              return Dismissible(
                key: Key(sub.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Subscription?"),
                      content: Text(
                        "Stop automating '${sub.title}'? Future expenses won't be created.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  provider.deleteSubscription(sub.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${sub.title} removed")),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purpleAccent.withValues(alpha: 0.1),
                    child: const Icon(Icons.loop, color: Colors.purpleAccent),
                  ),
                  title: Text(
                    sub.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${sub.interval} • Next: ${DateFormat('MMM dd').format(sub.nextDueDate)}",
                  ),
                  trailing: Text(
                    "₹${sub.amount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: const Text('Add Subscription'),
        icon: const Icon(Icons.add_alarm),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    String interval = 'Monthly';
    DateTime nextDue = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Subscription'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (e.g. Netflix)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category Dropdown (Simplified for now, can perform context.read to get list)
                  Consumer<ExpenseProvider>(
                    builder: (context, provider, _) {
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) => categoryController.text = val ?? '',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: interval,
                    decoration: const InputDecoration(
                      labelText: 'Interval',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Weekly', 'Monthly', 'Yearly']
                        .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                        .toList(),
                    onChanged: (val) => setState(() => interval = val!),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text("First Due Date"),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(nextDue)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: nextDue,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => nextDue = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      amountController.text.isNotEmpty &&
                      categoryController.text.isNotEmpty) {
                    final sub = RecurringExpense(
                      id: ExpenseApiService.generateExpenseId(), // using same ID gen for simplicity
                      title: titleController.text,
                      amount: double.parse(amountController.text),
                      category: categoryController.text,
                      nextDueDate: nextDue,
                      interval: interval,
                    );
                    context.read<ExpenseProvider>().addSubscription(sub);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
