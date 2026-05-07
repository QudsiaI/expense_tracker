import 'dart:developer';

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? editTransaction;
  final int? editKey;
  
  const AddTransactionScreen({
    super.key,
    this.editTransaction,
    this.editKey,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final StorageService _storage = StorageService();
  
  // Form controllers
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Selected values
  bool _isIncome = false;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  
  // Categories list from Hive
  List<CategoryModel> _categories = [];
  
  // Form validation
  final _formKey = GlobalKey<FormState>();
  
  // For edit mode
  bool _isEditMode = false;
  int? _editKey;

  @override
  void initState() {
    super.initState();
    _checkEditMode();
    _loadCategories();
  }

  void _loadCategories() {
    List<CategoryModel> allCategories = _storage.getAllCategories();
    
    if (_isEditMode && widget.editTransaction != null) {
      final txCategory = widget.editTransaction!.category;
      final categoryExists = allCategories.any((cat) => cat.name == txCategory);
      
      if (!categoryExists) {
        allCategories.add(CategoryModel(
          id: 'orphan_${DateTime.now().millisecondsSinceEpoch}',
          name: txCategory,
          isPredefined: false,
          icon: '📌',
        ));
      }
    }
    
    setState(() {
      _categories = allCategories;
      
      if (_isEditMode && widget.editTransaction != null) {
        // EDIT MODE - Pre-fill all data
        final tx = widget.editTransaction!;
        _isIncome = tx.isIncome;
        _selectedCategory = tx.category;
        _selectedDate = tx.date;
        _amountController.text = tx.amount.toString();
        _noteController.text = tx.note;

        // Debug prints
        log('=== PREFILLED EDIT DATA ===');
        log('Amount: ${_amountController.text}');
        log('Category: $_selectedCategory');
        log('IsIncome: $_isIncome');
        log('Date: $_selectedDate');
        log('Note: ${_noteController.text}');
      } else if (_categories.isNotEmpty) {
        _selectedCategory = _categories[0].name;
      }
    });
  }

  void _checkEditMode() {
    if (widget.editTransaction != null) {
      _isEditMode = true;
      _editKey = widget.editKey;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_isEditMode && _editKey != null) {
        final updatedTransaction = TransactionModel(
          id: widget.editTransaction!.id,
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
          note: _noteController.text.trim(),
          isIncome: _isIncome,
        );
        await _storage.updateTransaction(_editKey!, updatedTransaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully!')),
        );
      } else {
        final transaction = TransactionModel.create(
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
          note: _noteController.text.trim(),
          isIncome: _isIncome,
        );
        await _storage.addTransaction(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully!')),
        );
      }
      
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Simple Income/Expense Toggle
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isIncome ? Colors.blue.shade50 : Colors.transparent,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward, color: !_isIncome ? Colors.red : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Expense', style: TextStyle(color: !_isIncome ? Colors.red : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isIncome ? Colors.blue.shade50 : Colors.transparent,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, color: _isIncome ? Colors.green : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Income', style: TextStyle(color: _isIncome ? Colors.green : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category Dropdown (always visible, same label)
              // Category Dropdown with icons
DropdownButtonFormField<String>(
  initialValue: _selectedCategory,
  decoration: const InputDecoration(
    labelText: 'Category',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.category),
  ),
  items: _categories.map((category) {
    return DropdownMenuItem(
      value: category.name,
      child: Row(
        children: [
          Text(
            category.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Text(category.name),
        ],
      ),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      _selectedCategory = value!;
    });
  },
),
              
              const SizedBox(height: 16),
              
              // Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Note Field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Save Button (normal styling)
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isEditMode ? 'Update Transaction' : 'Save Transaction',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}