import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/api_integration.dart'; // For Expense and TransactionType
import 'package:xpensia/services/import_export_service.dart';
import 'package:xpensia/screens/stat/chart.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:xpensia/screens/budget/budget_screen.dart';
import 'package:xpensia/screens/recurring/recurring_screen.dart';

class StatScreen extends StatefulWidget {
  const StatScreen({super.key});

  @override
  State<StatScreen> createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarExpanded = false; // Collapsible calendar

  void _changeMonth(int months) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + months,
        1,
      );
      _selectedDay = null; // Reset selection on month change
    });
  }

  // Get Start and End Date for the selected month
  DateTime get _startDate =>
      DateTime(_currentMonth.year, _currentMonth.month, 1);
  DateTime get _endDate =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

  Map<DateTime, double> _getDailyExpenses(List<Expense> expenses) {
    Map<DateTime, double> dailyTotals = {};
    for (var e in expenses) {
      if (e.type == TransactionType.debit) {
        try {
          final dt = DateTime.parse(e.date);
          final dayKey = DateTime(dt.year, dt.month, dt.day);
          dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + e.amount;
        } catch (_) {}
      }
    }
    return dailyTotals;
  }

  double _calculateMonthlyTotal(List<Expense> expenses) {
    return expenses
        .where((e) {
          if (e.type != TransactionType.debit) return false;
          try {
            final date = DateTime.parse(e.date);
            return date.year == _currentMonth.year &&
                date.month == _currentMonth.month;
          } catch (_) {
            return false;
          }
        })
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthYear =
        "${_getMonthName(_currentMonth.month)} ${_currentMonth.year}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            final monthlyTotal = _calculateMonthlyTotal(provider.expenses);
            final dailyTotals = _getDailyExpenses(provider.expenses);

            return CustomScrollView(
              slivers: [
                // 1. Sleek Header
                SliverAppBar(
                  floating: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Analysis',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    // Month Selector Pill
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => _changeMonth(-1),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.chevron_left,
                                size: 20,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            monthYear,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _changeMonth(1),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 10),

                      // 2. Summary Card (Big Impact)
                      _StaggeredFadeIn(
                        index: 0,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Spent",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹${monthlyTotal.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Quick Actions Row inside the card for integration
                              Row(
                                children: [
                                  _buildQuickActionButton(
                                    context,
                                    icon: Icons.pie_chart_outline,
                                    label: "Budgets",
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BudgetScreen(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQuickActionButton(
                                    context,
                                    icon: Icons.loop,
                                    label: "Recurring",
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RecurringScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Category Breakdown (Pie Chart) Card
                      _StaggeredFadeIn(
                        index: 1,
                        child: _buildContentCard(
                          context,
                          title: "Spending Breakdown",
                          child: Column(
                            children: [
                              MyChart(startDate: _startDate, endDate: _endDate),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. Monthly Trend Card
                      _StaggeredFadeIn(
                        index: 2,
                        child: _buildContentCard(
                          context,
                          title: "6-Month Trend",
                          child: const MonthlyTrendChart(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. Calendar Toggle Card
                      _StaggeredFadeIn(
                        index: 3,
                        child: _buildContentCard(
                          context,
                          title: "Daily View - $monthYear",
                          padding: EdgeInsets.zero, // Calendar needs full width
                          headerAction: IconButton(
                            icon: Icon(
                              _isCalendarExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCalendarExpanded = !_isCalendarExpanded;
                              });
                            },
                          ),
                          child: AnimatedCrossFade(
                            firstChild: Container(), // Collapsed state
                            secondChild: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _currentMonth,
                                currentDay: DateTime.now(),
                                headerVisible: false,
                                startingDayOfWeek: StartingDayOfWeek.monday,
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekendStyle: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  weekdayStyle: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                calendarStyle: CalendarStyle(
                                  outsideDaysVisible: false,
                                  defaultTextStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  weekendTextStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  todayTextStyle: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: theme.colorScheme.secondary,
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _currentMonth = focusedDay;
                                  });
                                  _showDayDetails(
                                    context,
                                    selectedDay,
                                    provider.expenses,
                                  );
                                },
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, day, events) {
                                    final dayKey = DateTime(
                                      day.year,
                                      day.month,
                                      day.day,
                                    );
                                    final total = dailyTotals[dayKey];
                                    if (total != null && total > 0) {
                                      return Positioned(
                                        bottom: 4,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSameDay(_selectedDay, day)
                                                ? Colors.white
                                                : theme.colorScheme.error,
                                          ),
                                        ),
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                onPageChanged: (focusedDay) {
                                  if (_currentMonth.year == focusedDay.year &&
                                      _currentMonth.month == focusedDay.month) {
                                    return;
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() {
                                        _currentMonth = focusedDay;
                                      });
                                    }
                                  });
                                },
                              ),
                            ),
                            crossFadeState: _isCalendarExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 6. Download Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final expenses = provider.expenses.where((e) {
                              try {
                                final date = DateTime.parse(e.date);
                                final nextMonth = DateTime(
                                  _endDate.year,
                                  _endDate.month + 1,
                                  1,
                                );
                                return (date.isAfter(_startDate) ||
                                        date.isAtSameMomentAs(_startDate)) &&
                                    date.isBefore(nextMonth);
                              } catch (_) {
                                return false;
                              }
                            }).toList();
                            // ... Existing download logic ...
                            if (expenses.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "No data to report for this month",
                                  ),
                                ),
                              );
                              return;
                            }
                            await ImportExportService()
                                .generateAnddownloadPdfReport(
                                  expenses,
                                  startDate: _startDate,
                                  endDate: _endDate,
                                );
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text(
                            "Export Report",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: theme.colorScheme.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Helper Widgets & Methods ---

  Widget _buildContentCard(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? headerAction,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (headerAction != null) headerAction,
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return "";
  }

  void _showDayDetails(
    BuildContext context,
    DateTime date,
    List<Expense> allExpenses,
  ) {
    // Keep existing logic for day details
    final dayExpenses = allExpenses.where((e) {
      if (e.type != TransactionType.debit) return false;
      try {
        final eDate = DateTime.parse(e.date);
        return isSameDay(eDate, date);
      } catch (_) {
        return false;
      }
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Expenses on ${_getMonthName(date.month)} ${date.day}, ${date.year}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 15),
              if (dayExpenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No expenses for this day",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dayExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = dayExpenses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_downward,
                                color: Theme.of(context).colorScheme.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    expense.category,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "- ₹${expense.amount.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeIn({required this.index, required this.child});

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacity;
  late Animation<Offset> offset;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    offset = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: offset, child: widget.child),
    );
  }
}
