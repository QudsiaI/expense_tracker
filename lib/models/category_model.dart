import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final bool isPredefined;
  
  @HiveField(3)
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.isPredefined,
    required this.icon,
  });

  // Factory method for predefined categories
  factory CategoryModel.predefined(String name, String icon) {
    return CategoryModel(
      id: const Uuid().v4(),
      name: name,
      isPredefined: true,
      icon: icon,
    );
  }

  // Factory method for custom categories
  factory CategoryModel.custom(String name) {
    return CategoryModel(
      id: const Uuid().v4(),
      name: name,
      isPredefined: false,
      icon: '📌', // Default icon for custom categories
    );
  }

  // Get icon based on category name (for predefined)
  static String getIconForCategory(String name) {
    switch (name) {
      case 'Income':
        return '💰';
      case 'Food':
        return '🍔';
      case 'Travel':
        return '🚗';
      case 'Bills':
        return '💡';
      case 'Shopping':
        return '🛍️';
      default:
        return '📌';
    }
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, isPredefined: $isPredefined, icon: $icon)';
  }
}