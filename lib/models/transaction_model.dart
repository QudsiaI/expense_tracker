import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double amount;
  
  @HiveField(2)
  final String category;
  
  @HiveField(3)
  final DateTime date;
  
  @HiveField(4)
  final String note;
  
  @HiveField(5)
  final bool isIncome;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    required this.isIncome,
  });

  // Factory method to create a new transaction with auto-generated ID
  factory TransactionModel.create({
    required double amount,
    required String category,
    required DateTime date,
    required String note,
    required bool isIncome,
  }) {
    return TransactionModel(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      date: date,
      note: note,
      isIncome: isIncome,
    );
  }

  // // Convert to Map (for easy debugging)
  // Map<String, dynamic> toMap() {
  //   return {
  //     'id': id,
  //     'amount': amount,
  //     'category': category,
  //     'date': date,
  //     'note': note,
  //     'isIncome': isIncome,
  //   };
  // }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, category: $category, date: $date, note: $note, isIncome: $isIncome)';
  }
}