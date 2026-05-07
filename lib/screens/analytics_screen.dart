import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final StorageService _storage = StorageService();
  late ValueListenable<Box<TransactionModel>> _transactionListener;
  
  // Selected year for bar chart
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _transactionListener = Hive.box<TransactionModel>('transactions').listenable();
    _loadAvailableYears();
  }

  void _loadAvailableYears() {
    final transactions = _storage.getAllTransactions();
    final years = transactions.map((tx) => tx.date.year).toSet().toList();
    years.sort();
    _availableYears = years.isNotEmpty ? years : [DateTime.now().year];
    if (!_availableYears.contains(_selectedYear)) {
      _selectedYear = _availableYears.last;
    }
    setState(() {});
  }

  // Get monthly data for bar chart
  List<MonthlyData> _getMonthlyData() {
    final transactions = _storage.getAllTransactions();
    final months = List.generate(12, (i) => i + 1);
    final monthlyData = <MonthlyData>[];
    
    for (var month in months) {
      double income = 0;
      double expense = 0;
      
      for (var tx in transactions) {
        if (tx.date.year == _selectedYear && tx.date.month == month) {
          if (tx.isIncome) {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
      }
      
      monthlyData.add(MonthlyData(
        month: month,
        income: income,
        expense: expense,
      ));
    }
    
    return monthlyData;
  }

  // Get category expense data for pie chart (current month)
  Map<String, double> _getCategoryExpenses() {
    final now = DateTime.now();
    final transactions = _storage.getAllTransactions();
    final categoryExpenses = <String, double>{};
    
    for (var tx in transactions) {
      // Only include expenses from current month, exclude Income category
      if (!tx.isIncome && 
          tx.date.month == now.month && 
          tx.date.year == now.year &&
          tx.category != 'Income') {
        categoryExpenses[tx.category] = (categoryExpenses[tx.category] ?? 0) + tx.amount;
      }
    }
    
    return categoryExpenses;
  }

  // Get colors for pie chart
  List<Color> _getPieColors(int index) {
    const colors = [
      Color(0xFF4CAF50), // Green - Food
      Color(0xFF2196F3), // Blue - Travel
      Color(0xFFFF9800), // Orange - Bills
      Color(0xFF9C27B0), // Purple - Shopping
      Color(0xFFF44336), // Red - Others
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF795548), // Brown
    ];
    return [colors[index % colors.length]];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          // Year selector dropdown
          if (_availableYears.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: DropdownButton<int>(
                value: _selectedYear,
                items: _availableYears.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value!;
                  });
                },
                underline: const SizedBox(),
              ),
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _transactionListener,
        builder: (context, Box<TransactionModel> box, _) {
          final categoryExpenses = _getCategoryExpenses();
          final monthlyData = _getMonthlyData();
          final hasExpenses = categoryExpenses.isNotEmpty;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pie Chart Section
                const Text(
                  'Current Month Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By Category',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pie Chart
                if (hasExpenses)
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieSections(categoryExpenses),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  )
                else
                  _buildEmptyPieChart(),
                
                const SizedBox(height: 16),
                
                // Pie Chart Legend
                if (hasExpenses)
                  _buildPieLegend(categoryExpenses),
                
                const SizedBox(height: 32),
                
                // Bar Chart Section
                const Text(
                  'Monthly Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Year $_selectedYear',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Bar Chart
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      groupsSpace: 20,
                      maxY: _getMaxYValue(monthlyData),
                      titlesData: _buildTitlesData(),
                      barGroups: _buildBarGroups(monthlyData),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bar Chart Legend
                _buildBarLegend(),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> categoryExpenses) {
    final total = categoryExpenses.values.reduce((a, b) => a + b);
    final entries = categoryExpenses.entries.toList();
    final List<PieChartSectionData> sections = [];
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percentage = (entry.value / total) * 100;
      
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: _getPieColors(i)[0],
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return sections;
  }

  Widget _buildPieLegend(Map<String, double> categoryExpenses) {
    final entries = categoryExpenses.entries.toList();
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value.key;
        final amount = entry.value.value;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getPieColors(index)[0],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$category: Rs. ${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  FlTitlesData _buildTitlesData() {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < 12) {
              return Text(
                monthNames[index],
                style: const TextStyle(fontSize: 10),
              );
            }
            return const Text('');
          },
          reservedSize: 30,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            return Text(
              'Rs. ${(value / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<MonthlyData> monthlyData) {
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < monthlyData.length; i++) {
      final data = monthlyData[i];
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data.income,
              color: Colors.green,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: data.expense,
              color: Colors.red,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          barsSpace: 0,
        ),

      );
    }
    
    return barGroups;
  }

  double _getMaxYValue(List<MonthlyData> monthlyData) {
    double maxValue = 0;
    for (var data in monthlyData) {
      if (data.income > maxValue) maxValue = data.income;
      if (data.expense > maxValue) maxValue = data.expense;
    }
    return maxValue == 0 ? 50000 : maxValue * 1.1; // Add 10% padding
  }

  Widget _buildEmptyPieChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No expenses this month',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Add transactions to see analytics',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            const Text('Income', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            const Text('Expense', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// Helper class for monthly data
class MonthlyData {
  final int month;
  final double income;
  final double expense;
  
  MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
  });
}