import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/data/api_integration.dart';

class MyChart extends StatefulWidget {
  const MyChart({super.key});

  @override
  State<MyChart> createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        if (expenseProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (expenseProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading chart data',
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => expenseProvider.refreshExpenses(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        return BarChart(mainBarChart(expenseProvider.expenses));
      },
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(

          toY: y,
          width: 15, 
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary,
            ],
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> showingGroups(List<Expense> expenses) {
    final now = DateTime.now();
    Map<int, double> weeklyExpenses = {};
    
    for (int i = 0; i < 8; i++) {
      weeklyExpenses[i] = 0;
    }

    for (var expense in expenses) {
      try {
        final expenseDate = DateTime.parse(expense.date);
        final daysDiff = now.difference(expenseDate).inDays;
        final weeksDiff = (daysDiff / 7).floor();
        
        if (weeksDiff >= 0 && weeksDiff < 8) {
          int index = 7 - weeksDiff; 
          weeklyExpenses[index] = (weeklyExpenses[index] ?? 0) + expense.amount;
        }
      } catch (e) {

        continue;
      }
    }

    return List.generate(8, (i) {
      double value = (weeklyExpenses[i] ?? 0) / 1000; 
      return makeGroupData(i, value);
    });
  }

  BarChartData mainBarChart(List<Expense> expenses) {
    return BarChartData(
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: leftTiles,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: getTiles,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: false),
      barGroups: showingGroups(expenses),
      maxY: 10,
    );
  }

  Widget getTiles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );
    
    final now = DateTime.now();
    final targetDate = now.subtract(Duration(days: (7 - value.toInt()) * 7));
    
    String weekText;
    int weeksDiff = 7 - value.toInt();
    
    if (weeksDiff == 0) {
      weekText = "This\nWeek";
    } else if (weeksDiff == 1) {
      weekText = "Last\nWeek";
    } else {
      // Show week starting date
      final weekStart = targetDate.subtract(Duration(days: targetDate.weekday - 1));
      weekText = "${weekStart.day}/${weekStart.month}";
    }
    
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: Text(weekText, style: style, textAlign: TextAlign.center),
    );
  }

  Widget leftTiles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );
    
    String text;
    if (value == 0) {
      text = "₹0";
    } else if (value == 4) {
      text = "₹4K";
    } else if (value == 8) {
      text = "₹8K";
    } else if (value == 12) {
      text = "₹12K";
    } else if (value == 16) {
      text = "₹16K";
    } else if (value == 20) {
      text = "₹20K";
    } else {
      return Container();
    }
    
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: Text(text, style: style),
    );
  }
}