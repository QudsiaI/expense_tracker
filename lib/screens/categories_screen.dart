import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final StorageService _storage = StorageService();

  late ValueListenable<Box<CategoryModel>> _categoryListener;

  @override
  void initState() {
    super.initState();
    _categoryListener = Hive.box<CategoryModel>('categories').listenable();
  }

  // ==================== ADD CATEGORY ====================
  void _addCustomCategory() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Category'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter category name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  if (_storage.isCategoryNameExists(
                    name,
                    caseSensitive: false,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category already exists!')),
                    );
                    return;
                  }

                  final newCategory = CategoryModel.custom(name);
                  await _storage.addCategory(newCategory);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category "$name" added')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // ==================== EDIT CATEGORY ====================
  void _editCategory(CategoryModel category, int key) {
    final TextEditingController nameController = TextEditingController(
      text: category.name,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter new category name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != category.name) {
                  // Check if new name already exists
                  if (_storage.isCategoryNameExists(newName)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category already exists!')),
                    );
                    return;
                  }

                  // Update the category itself
                  final updatedCategory = CategoryModel(
                    id: category.id,
                    name: newName,
                    isPredefined: false,
                    icon: category.icon,
                  );
                  await _storage.updateCategory(key, updatedCategory);

                  // Update all transactions that use this category
                  await _updateTransactionsCategory(category.name, newName);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Category renamed to "$newName" and transactions updated!',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ==================== DELETE CATEGORY ====================
  void _deleteCategory(CategoryModel category, int key) async {
    // Prevent deletion of predefined categories
    if (category.isPredefined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete predefined categories'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if category is used in any transaction
    final allTransactions = _storage.getAllTransactions();
    final transactionsWithCategory = allTransactions
        .where((tx) => tx.category == category.name)
        .toList();

    if (transactionsWithCategory.isNotEmpty) {
      _showDeleteCategoryWarning(
        category,
        key,
        transactionsWithCategory.length,
      );
    } else {
      _confirmDeleteCategory(category, key);
    }
  }

  void _showDeleteCategoryWarning(
    CategoryModel category,
    int key,
    int transactionCount,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Category Has Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The category "${category.name}" is used in $transactionCount transaction(s).',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'What would you like to do?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final defaultCategory = _getDefaultCategory();
                await _reassignTransactions(category.name, defaultCategory);
                await _storage.deleteCategory(key);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Category "${category.name}" deleted. Transactions moved to "$defaultCategory".',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Reassign & Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(CategoryModel category, int key) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _storage.deleteCategory(key);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" deleted'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _getDefaultCategory() {
    final categories = _storage.getAllCategories();

    final othersCategory = categories.firstWhere(
      (cat) => cat.name == 'Others',
      orElse: () => categories.first,
    );

    return othersCategory.name;
  }

  Future<void> _reassignTransactions(
    String oldCategory,
    String newCategory,
  ) async {
    final allTransactions = _storage.getAllTransactions();
    final transactionsToUpdate = allTransactions
        .where((tx) => tx.category == oldCategory)
        .toList();

    for (var tx in transactionsToUpdate) {
      final box = Hive.box<TransactionModel>('transactions');
      final key = box.keyAt(box.values.toList().indexOf(tx));

      final updatedTransaction = TransactionModel(
        id: tx.id,
        amount: tx.amount,
        category: newCategory,
        date: tx.date,
        note: tx.note,
        isIncome: tx.isIncome,
      );

      await _storage.updateTransaction(key, updatedTransaction);
    }
  }

  // ==================== BUILD METHODS ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addCustomCategory,
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Category'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Categories list
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _categoryListener,
              builder: (context, Box<CategoryModel> box, _) {
                final categories = box.values.toList();
                final predefined = categories
                    .where((c) => c.isPredefined)
                    .toList();
                final custom = categories
                    .where((c) => !c.isPredefined)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Predefined Categories Section
                    const Text(
                      'DEFAULT CATEGORIES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...predefined.map(
                      (category) => _buildCategoryTile(
                        category,
                        box.keyAt(box.values.toList().indexOf(category)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Custom Categories Section
                    if (custom.isNotEmpty) ...[
                      const Text(
                        'MY CATEGORIES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...custom.map(
                        (category) => _buildCategoryTile(
                          category,
                          box.keyAt(box.values.toList().indexOf(category)),
                        ),
                      ),
                    ] else ...[
                      _buildEmptyCustomCategories(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(CategoryModel category, int key) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(category.icon, style: const TextStyle(fontSize: 28)),
        title: Text(category.name, style: const TextStyle(fontSize: 16)),
        trailing: category.isPredefined
            ? const Icon(Icons.lock, color: Colors.grey, size: 20)
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCategory(category, key);
                  } else if (value == 'delete') {
                    _deleteCategory(category, key);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
        onLongPress: !category.isPredefined
            ? () => _showLongPressMenu(category, key)
            : null,
      ),
    );
  }

  Widget _buildEmptyCustomCategories() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            'No custom categories yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Custom Category" to create one',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showLongPressMenu(CategoryModel category, int key) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Category'),
                onTap: () {
                  Navigator.pop(context);
                  _editCategory(category, key);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Category',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteCategory(category, key);
                },
              ),
              // const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateTransactionsCategory(
    String oldCategoryName,
    String newCategoryName,
  ) async {
    final allTransactions = _storage.getAllTransactions();
    final transactionsToUpdate = allTransactions
        .where((tx) => tx.category == oldCategoryName)
        .toList();

    for (var tx in transactionsToUpdate) {
      final box = Hive.box<TransactionModel>('transactions');
      final key = box.keyAt(box.values.toList().indexOf(tx));

      final updatedTransaction = TransactionModel(
        id: tx.id,
        amount: tx.amount,
        category: newCategoryName,
        date: tx.date,
        note: tx.note,
        isIncome: tx.isIncome,
      );

      await _storage.updateTransaction(key, updatedTransaction);
    }

    // Optional: Show debug print
    log(
      'Updated ${transactionsToUpdate.length} transactions from "$oldCategoryName" to "$newCategoryName"',
    );
  }
}
