import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/api_integration.dart';

class MyChart extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const MyChart({super.key, this.startDate, this.endDate});

  @override
  State<MyChart> createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> {
  int touchedIndex = -1;

  // Premium Color Palette
  final List<Color> _colors = [
    Colors.amberAccent, // Gold
    Colors.blueAccent, // Royal Blue
    Colors.purpleAccent, // Deep Purple
    Colors.tealAccent, // Emerald
    Colors.redAccent, // Crimson
    Colors.orangeAccent, // Sunset
    Colors.cyanAccent,
    Colors.pinkAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        if (expenseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categoryData = _processData(expenseProvider.expenses);

        if (categoryData.isEmpty) {
          return Center(
            child: Text(
              "No expenses for this period.",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        return Column(
          children: [
            // PIE CHART
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2, // Gap between sections for 3D feel
                      centerSpaceRadius: 50, // Donut style
                      sections: _buildPieSections(categoryData),
                    ),
                  ),
                  // Center Text (Total or Selection)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${_calculateTotal(categoryData).toStringAsFixed(0)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black
                                  : Colors.grey.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // LEGEND (Custom Premium Look)
            Column(
              children: categoryData.entries.map((entry) {
                final index = categoryData.keys.toList().indexOf(entry.key);
                final color = _colors[index % _colors.length];
                final isTouched = index == touchedIndex;
                final total = _calculateTotal(categoryData);
                final percentage = (entry.value / total * 100).toStringAsFixed(
                  1,
                );

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 16,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: isTouched
                        ? color.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isTouched
                        ? Border.all(color: color.withValues(alpha: 0.5))
                        : Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      // Color Indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),

                      // Category Name
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Percentage
                      Text(
                        "$percentage%",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 15),

                      // Amount
                      Text(
                        "₹${entry.value.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // Group Expenses by Category
  Map<String, double> _processData(List<Expense> expenses) {
    final Map<String, double> data = {};
    for (var e in expenses) {
      if (e.type == TransactionType.debit) {
        // Date Filtering
        if (widget.startDate != null) {
          try {
            final date = DateTime.parse(e.date);
            if (date.isBefore(widget.startDate!)) continue;
          } catch (_) {}
        }
        if (widget.endDate != null) {
          try {
            final date = DateTime.parse(e.date);
            if (date.isAfter(widget.endDate!.add(const Duration(days: 1)))) {
              continue;
            }
          } catch (_) {}
        }

        data[e.category] = (data[e.category] ?? 0) + e.amount;
      }
    }
    // Sort by value descending
    var sortedKeys = data.keys.toList(growable: false)
      ..sort((k1, k2) => data[k2]!.compareTo(data[k1]!));

    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, data[k]!)));
  }

  double _calculateTotal(Map<String, double> data) {
    return data.values.fold(0, (sum, item) => sum + item);
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final List<PieChartSectionData> sections = [];
    final total = _calculateTotal(data);
    int index = 0;

    data.forEach((key, value) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius = isTouched ? 65 : 55; // Pop out effect
      final color = _colors[index % _colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${(value / total * 100).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Contrast text for inside pie
            shadows: [Shadow(color: Colors.white54, blurRadius: 2)],
          ),
          badgeWidget: isTouched
              ? Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color, blurRadius: 5)],
                  ),
                  child: Icon(_getCategoryIcon(key), color: color, size: 16),
                )
              : null,
          badgePositionPercentageOffset: 1.3,
          titlePositionPercentageOffset: 0.55,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.7), // Light top for 3D shine
              color, // Normal
              color.withValues(alpha: 0.8), // Darker bottom
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
      );
      index++;
    });

    return sections;
  }

  IconData _getCategoryIcon(String category) {
    // Simplified icon mapper for badges (duplicate of logic in screens, ideally moved to utils)
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'shopping':
        return Icons.shopping_bag;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'health':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }
}

// ---------------------------------------------------------------------------
// MONTHLY TREND CHART (Bar Chart for Last 6 Months)
// ---------------------------------------------------------------------------
class MonthlyTrendChart extends StatelessWidget {
  const MonthlyTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final monthlyData = _getLast6MonthsData(provider.expenses);

        if (monthlyData.isEmpty || monthlyData.values.every((v) => v == 0)) {
          return const SizedBox(
            height: 50,
            child: Center(
              child: Text(
                "No trend data available",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        double maxY = monthlyData.values.reduce((a, b) => a > b ? a : b);
        if (maxY == 0) maxY = 100;
        // Add buffer to maxY
        maxY = maxY * 1.2;

        return AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${monthlyData.keys.elementAt(group.x.toInt())}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '₹${rod.toY.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= monthlyData.length) {
                        return const SizedBox();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          monthlyData.keys.elementAt(value.toInt()),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(monthlyData.length, (index) {
                final value = monthlyData.values.elementAt(index);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Map<String, double> _getLast6MonthsData(List<Expense> expenses) {
    Map<String, double> data = {};
    DateTime now = DateTime.now();

    // Initialize last 6 months
    for (int i = 5; i >= 0; i--) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      // Format as "Jan", "Feb"
      String key = _getMonthName(monthDate.month);
      data[key] = 0.0;
    }

    // Populate data
    for (var e in expenses) {
      if (e.type == TransactionType.debit) {
        try {
          DateTime date = DateTime.parse(e.date);
          // Check if within last 6 months approx
          if (date.isAfter(DateTime(now.year, now.month - 6, 1))) {
            String key = _getMonthName(date.month);
            if (data.containsKey(key)) {
              data[key] = (data[key] ?? 0) + e.amount;
            }
          }
        } catch (_) {}
      }
    }
    return data;
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return "";
  }
}
