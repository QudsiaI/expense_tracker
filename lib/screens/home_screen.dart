import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../controllers/home_controller.dart';
import '../models/transaction_model.dart';
import '../widgets/summary_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/largest_expense_card.dart';
import '../widgets/empty_state.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  late ValueListenable<Box<TransactionModel>> _transactionListener;

  @override
  void initState() {
    super.initState();
    _transactionListener = Hive.box<TransactionModel>(
      'transactions',
    ).listenable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: _transactionListener,
        builder: (context, Box<TransactionModel> box, _) {
          final transactions = box.values.toList();
          final homeData = _controller.getHomeData(transactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                const Text(
                  'Welcome, User! 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // Monthly Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Income',
                        amount: homeData.monthlyIncome,
                        color: Colors.green,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: 'Expenses',
                        amount: homeData.monthlyExpenses,
                        color: Colors.red,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Balance Cards
                BalanceCard(
                  balance: homeData.monthlyBalance,
                  title: 'Monthly Balance',
                ),

                const SizedBox(height: 12),

                BalanceCard(
                  balance: homeData.totalBalance,
                  title: 'Total Balance',
                ),

                const SizedBox(height: 24),

                // Largest Expense Section
                if (homeData.largestExpense != null)
                  LargestExpenseCard(expense: homeData.largestExpense!)
                else
                  const EmptyState(
                    title: 'No expenses this month',
                    subtitle: 'Tap + to add your first transaction',
                    icon: Icons.info_outline,
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
