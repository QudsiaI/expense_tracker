import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storage = StorageService();
  late ValueListenable<Box<TransactionModel>> _transactionListener;

    // Filter variables
  String _selectedFilterCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _transactionListener = Hive.box<TransactionModel>('transactions').listenable();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = _storage.getAllCategories();
    });
  }

  // Apply filters to transactions
  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    return transactions.where((tx) {
      // Category filter
      if (_selectedFilterCategory != 'All' && tx.category != _selectedFilterCategory) {
        return false;
      }
      
      // Date range filter
      if (_startDate != null && tx.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && tx.date.isAfter(_endDate!)) {
        return false;
      }
      
      return true;
    }).toList();
  }

  // Calculate total balance (all time)
  double _calculateTotalBalance(List<TransactionModel> transactions) {
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

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format date for filter display
  String _formatDateForDisplay(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedFilterCategory = 'All';
      _startDate = null;
      _endDate = null;
    });
  }

  // Show date range picker
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // Delete transaction
  Future<void> _deleteTransaction(int key, TransactionModel transaction) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Delete ${transaction.isIncome ? 'income' : 'expense'} of Rs. ${transaction.amount.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _storage.deleteTransaction(key);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Edit transaction
  Future<void> _editTransaction(TransactionModel transaction, int key) async {
    // Navigate to add transaction screen with existing data
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          editTransaction: transaction,
          editKey: key,
        ),
      ),
    );
    
    // Refresh is automatic due to ValueListenableBuilder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterBottomSheet(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _transactionListener,
        builder: (context, Box<TransactionModel> box, _) {
          final allTransactions = box.values.toList();
          // Sort by date (newest first)
          allTransactions.sort((a, b) => b.date.compareTo(a.date));
          final filteredTransactions = _filterTransactions(allTransactions);
          final totalBalance = _calculateTotalBalance(filteredTransactions);
          final hasActiveFilters = _selectedFilterCategory != 'All' || _startDate != null || _endDate != null;

          if (filteredTransactions.isEmpty) {
            return _buildEmptyState(hasActiveFilters);
          }

          return Column(
            children: [

              // Active filters banner (if any filters active)
              if (hasActiveFilters)
                _buildActiveFiltersBanner(),

              // Balance Card at Top
              _buildBalanceCard(totalBalance),
              
              // Transaction List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    final key = box.keyAt(box.values.toList().indexOf(transaction));
                    return _buildTransactionTile(transaction, key);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
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
          // Refresh is automatic due to ValueListenableBuilder
        },
        child: const Icon(Icons.add),
      ),
    );
  }
void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Filter Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Category Filter
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilterCategory,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All Categories'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem(
                              value: category.name,
                              child: Text(category.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setStateBottomSheet(() {
                            _selectedFilterCategory = value!;
                          });
                          setState(() {
                            _selectedFilterCategory = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date Range Filter
                  const Text(
                    'Date Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selectDateRange,
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${_formatDateForDisplay(_startDate)} - ${_formatDateForDisplay(_endDate)}'
                                : 'Select Range',
                          ),
                        ),
                      ),
                      if (_startDate != null || _endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setStateBottomSheet(() {
                              _startDate = null;
                              _endDate = null;
                            });
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _clearFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveFiltersBanner() {
    List<String> activeFilters = [];
    if (_selectedFilterCategory != 'All') activeFilters.add('Category: $_selectedFilterCategory');
    if (_startDate != null) activeFilters.add('From: ${_formatDateForDisplay(_startDate)}');
    if (_endDate != null) activeFilters.add('To: ${_formatDateForDisplay(_endDate)}');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activeFilters.join(' • '),
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: balance >= 0 
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Balance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction, int key) {
    final isIncome = transaction.isIncome;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading Icon
            CircleAvatar(
              backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            
            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (transaction.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Trailing Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editTransaction(transaction, key);
                    } else if (value == 'delete') {
                      _deleteTransaction(key, transaction);
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasActiveFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasActiveFilters ? Icons.filter_alt_off : Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters ? 'No matching transactions' : 'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters 
                ? 'Try changing your filter criteria'
                : 'Tap + to add your first transaction',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
}