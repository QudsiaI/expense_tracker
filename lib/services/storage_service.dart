import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Box references
  late Box<TransactionModel> _transactionBox;
  late Box<CategoryModel> _categoryBox;

  // Initialize boxes
  Future<void> init() async {
    _transactionBox = await Hive.openBox<TransactionModel>('transactions');
    _categoryBox = await Hive.openBox<CategoryModel>('categories');
    
    // Initialize default categories if box is empty
    if (_categoryBox.isEmpty) {
      await _initDefaultCategories();
    }
  }

  // Initialize default categories
  Future<void> _initDefaultCategories() async {
    final defaultCategories = [

      // Income sources
    CategoryModel.predefined('Salary', '💰'),
    CategoryModel.predefined('Freelance', '💼'),
    CategoryModel.predefined('Gift', '🎁'),
    CategoryModel.predefined('Investment', '📈'),
    
    // Expense categories
      CategoryModel.predefined('Food', '🍔'),
      CategoryModel.predefined('Travel', '🚗'),
      CategoryModel.predefined('Bills', '💡'),
      CategoryModel.predefined('Shopping', '🛍️'),
      CategoryModel.predefined('Others', '📌'),
    ];
    
    for (var category in defaultCategories) {
      await _categoryBox.add(category);
    }
  }

  // ========== TRANSACTION METHODS ==========
  
  // Get all transactions
  List<TransactionModel> getAllTransactions() {
    return _transactionBox.values.toList();
  }

  // Get transactions sorted by date (newest first)
  List<TransactionModel> getTransactionsSortedByDate() {
    final transactions = _transactionBox.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  // Add transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionBox.add(transaction);
  }

  // Update transaction
  Future<void> updateTransaction(int key, TransactionModel transaction) async {
    await _transactionBox.put(key, transaction);
  }

  // Delete transaction
  Future<void> deleteTransaction(int key) async {
    await _transactionBox.delete(key);
  }

  // Get transaction by key
  TransactionModel? getTransaction(int key) {
    return _transactionBox.get(key);
  }

  // Get all transaction keys
  Iterable<dynamic> getTransactionKeys() {
    return _transactionBox.keys;
  }

  // ========== CATEGORY METHODS ==========
  
  // Get all categories
  List<CategoryModel> getAllCategories() {
    return _categoryBox.values.toList();
  }

  // Get only custom categories (not predefined)
  List<CategoryModel> getCustomCategories() {
    return _categoryBox.values.where((cat) => !cat.isPredefined).toList();
  }

  // Get only predefined categories
  List<CategoryModel> getPredefinedCategories() {
    return _categoryBox.values.where((cat) => cat.isPredefined).toList();
  }

  // Add custom category
  Future<void> addCategory(CategoryModel category) async {
    await _categoryBox.add(category);
  }

  // Update category
  Future<void> updateCategory(int key, CategoryModel category) async {
    await _categoryBox.put(key, category);
  }

  // Delete category (only custom ones)
  Future<void> deleteCategory(int key) async {
    final category = _categoryBox.get(key);
    if (category != null && !category.isPredefined) {
      await _categoryBox.delete(key);
    }
  }

  // Get category by key
  CategoryModel? getCategory(int key) {
    return _categoryBox.get(key);
  }

  // Get all category keys
  Iterable<dynamic> getCategoryKeys() {
    return _categoryBox.keys;
  }

  // Check if a category name already exists
  bool isCategoryNameExists(String name, {bool caseSensitive = false}) {
  if (caseSensitive) {
    return _categoryBox.values.any((cat) => cat.name == name);
  } else {
    return _categoryBox.values.any((cat) => cat.name.toLowerCase() == name.toLowerCase());
  }
}

  // ========== UTILITY METHODS ==========
  
  // Clear all data (for testing)
  Future<void> clearAllData() async {
    await _transactionBox.clear();
    await _categoryBox.clear();
    await _initDefaultCategories(); // Re-initialize default categories
  }

  

  // Check if a category is used in any transaction
  bool isCategoryUsed(String categoryName) {
    return _transactionBox.values.any((transaction) => transaction.category == categoryName);
  }
}