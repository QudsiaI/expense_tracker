import '../services/storage_service.dart';
import '../models/transaction_model.dart';

class HomeController {
  final StorageService _storage = StorageService();
  
  // Get all transactions
  List<TransactionModel> getTransactions() {
    return _storage.getAllTransactions();
  }
  
  // Calculate total balance (all-time)
  double calculateTotalBalance(List<TransactionModel> transactions) {
    double balance = 0;
    for (var tx in transactions) {
      if (tx.isIncome) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    return balance;
  }
  
  // Calculate total income for current month
  double calculateMonthlyIncome(List<TransactionModel> transactions) {
    final now = DateTime.now();
    double total = 0;
    for (var tx in transactions) {
      if (tx.date.month == now.month && 
          tx.date.year == now.year && 
          tx.isIncome) {
        total += tx.amount;
      }
    }
    return total;
  }
  
  // Calculate total expenses for current month
  double calculateMonthlyExpenses(List<TransactionModel> transactions) {
    final now = DateTime.now();
    double total = 0;
    for (var tx in transactions) {
      if (tx.date.month == now.month && 
          tx.date.year == now.year && 
          !tx.isIncome) {
        total += tx.amount;
      }
    }
    return total;
  }
  
  // Calculate monthly balance
  double calculateMonthlyBalance(List<TransactionModel> transactions) {
    return calculateMonthlyIncome(transactions) - calculateMonthlyExpenses(transactions);
  }
  
  // Find largest expense this month
  TransactionModel? getLargestExpense(List<TransactionModel> transactions) {
    final now = DateTime.now();
    TransactionModel? largestExpense;
    double maxAmount = 0;
    
    for (var tx in transactions) {
      if (tx.date.month == now.month && 
          tx.date.year == now.year && 
          !tx.isIncome) {
        if (tx.amount > maxAmount) {
          maxAmount = tx.amount;
          largestExpense = tx;
        }
      }
    }
    return largestExpense;
  }
  
  // Get monthly data for home screen (all calculations at once)
  HomeData getHomeData(List<TransactionModel> transactions) {
    return HomeData(
      monthlyIncome: calculateMonthlyIncome(transactions),
      monthlyExpenses: calculateMonthlyExpenses(transactions),
      monthlyBalance: calculateMonthlyBalance(transactions),
      totalBalance: calculateTotalBalance(transactions),
      largestExpense: getLargestExpense(transactions),
    );
  }
}

// Data class to hold all home screen calculations
class HomeData {
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlyBalance;
  final double totalBalance;
  final TransactionModel? largestExpense;
  
  HomeData({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlyBalance,
    required this.totalBalance,
    this.largestExpense,
  });
}