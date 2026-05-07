### Personal Expense Tracker


## 📱 Overview

Personal Expense Tracker is a comprehensive financial management application that helps users track their income and expenses, manage custom categories, and visualize spending patterns through interactive charts. Built with Flutter and Hive for offline-first performance.


## Core Features

### Dashboard (Home Screen)
- **Monthly Summary Cards** - Quick view of income, expenses, and balance
- **Total Balance** - Lifetime financial position
- **Largest Expense Highlight** - Identifies biggest spending category
- **Real-time Updates** - Auto-refreshes when data changes

### Transaction Management
- **Add Transactions** - Income/Expense toggle with amount, category, date, and notes
- **Edit Transactions** - Modify existing entries
- **Delete Transactions** - With confirmation dialog
- **Smart Validation** - Prevents negative amounts and invalid inputs

### Transaction History
- **Chronological List** - Newest transactions first
- **Color Coding** - Green for income, Red for expenses
- **Advanced Filtering**:
  - Category filter (specific or all categories)
  - Date range filter (start to end date)
  - Active filters banner with clear option
- **Quick Actions** - Edit/Delete via popup menu

### Category Management
- **Predefined Categories**: Income, Food, Travel, Bills, Shopping, Others
- **Custom Categories** - Users can add their own
- **Protected Defaults** - Predefined categories cannot be deleted
- **Smart Deletion** - Warns if category is used in transactions
- **Transaction Reassignment** - Move transactions to "Others" when deleting used categories

### Analytics & Insights
- **Pie Chart** - Current month expenses breakdown by category
  - Shows percentage and amount
  - Color-coded with legend
  - Empty state handling
- **Bar Chart** - Monthly income vs expenses comparison
  - Year selector dropdown
  - Proper Y-axis scaling
  - Income (Green) / Expense (Red) bars side by side

### Data Management
- **Local Storage** - Offline-first with Hive database
- **Persistent Data** - Survives app restarts and phone reboots
- **Automatic Backups** - Data stored in device's internal storage

---

## Architecture

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Home    │ │ History  │ │Category  │ │Analytics │      │
│  │  Screen  │ │ Screen   │ │ Screen   │ │ Screen   │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      WIDGETS LAYER                           │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │SummaryCard │ │BalanceCard │ │EmptyState  │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     CONTROLLER LAYER                         │
│  ┌────────────────────────────────────────────────────┐     │
│  │                 HomeController                      │     │
│  │  - calculateMonthlyIncome()                        │     │
│  │  - calculateMonthlyExpenses()                      │     │
│  │  - calculateTotalBalance()                         │     │
│  │  - getLargestExpense()                             │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                           │
│  ┌────────────────────────────────────────────────────┐     │
│  │                StorageService                       │     │
│  │  - CRUD Operations                                 │     │
│  │  - Hive Box Management                             │     │
│  │  - Singleton Pattern                               │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │ TransactionModel │      │  CategoryModel   │            │
│  │ - id (UUID)      │      │ - id (UUID)      │            │
│  │ - amount         │      │ - name           │            │
│  │ - category       │      │ - isPredefined   │            │
│  │ - date           │      │ - icon           │            │
│  │ - note           │      └──────────────────┘            │
│  │ - isIncome       │                                       │
│  └──────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │                  Hive Database                      │     │
│  │  📦 transactions.box  │  📦 categories.box        │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```


## 🎯 State Management

### ValueListenableBuilder (Built-in Flutter)

This project uses **`ValueListenableBuilder`** - Flutter's built-in reactive state management solution.

**Why not GetX/Provider/BLoC?**
- ✅ Perfect for this app's scale (no complex state sharing needed)
- ✅ Zero additional dependencies
- ✅ Excellent performance
- ✅ Automatic UI updates when Hive data changes
- ✅ Simple and maintainable

**How it works:**

```dart
// 1. Create a listener
late ValueListenable<Box<TransactionModel>> _transactionListener;

// 2. Initialize in initState
_transactionListener = Hive.box<TransactionModel>('transactions').listenable();

// 3. Use in UI - Auto rebuilds on data changes
ValueListenableBuilder(
  valueListenable: _transactionListener,
  builder: (context, Box<TransactionModel> box, _) {
    final transactions = box.values.toList();
    // UI automatically updates when transactions change
  },
)
```

**Benefits for this project:**
- Real-time updates across all screens
- No manual `setState()` calls needed
- Perfect integration with Hive database
- Minimal boilerplate code

---

## Local Storage Solution

### Hive Database

**Why Hive?**

| Feature | Hive | SQLite | SharedPreferences |
|---------|------|--------|-------------------|
| **Speed** | ⚡ Very Fast | 🐢 Slower | ⚡ Fast |
| **Type Safety** | ✅ Yes | ⚠️ Manual | ❌ No |
| **Complex Objects** | ✅ Yes | ✅ Yes | ❌ No |
| **Ease of Use** | ✅ Easy | ⚠️ Complex | ✅ Easy |
| **Cross-Platform** | ✅ Yes | ✅ Yes | ✅ Yes |

**Data Persistence Features:**
- ✅ Data survives app restarts
- ✅ Data survives phone reboots
- ✅ Fast read/write operations
- ✅ Automatic binary serialization
- ✅ Type-safe with code generation

---

## Key Packages & Libraries

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter** | SDK | UI framework |
| **hive_flutter** | ^1.1.0 | Local database with Flutter integration |
| **hive_generator** | ^2.0.0 | Code generation for Hive adapters |
| **build_runner** | ^2.4.0 | Dart code generation runner |

### UI & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| **fl_chart** | ^0.68.0 | Beautiful charts (pie, bar) |
| **uuid** | ^4.3.3 | Unique ID generation |
| **intl** | ^0.19.0 | Date formatting |


---

## 🗂️ Project Structure

```
lib/
├── controllers/
│   └── home_controller.dart         # Business logic & calculations
│
├── models/
│   ├── transaction_model.dart       # Transaction data model (Hive)
│   └── category_model.dart          # Category data model (Hive)
│
├── screens/
│   ├── home_screen.dart             # Dashboard with summary
│   ├── history_screen.dart          # Transaction list with filters
│   ├── categories_screen.dart       # Category management
│   ├── analytics_screen.dart        # Charts & analytics
│   └── add_transaction_screen.dart  # Add/edit transaction form
│
├── services/
│   └── storage_service.dart         # Hive CRUD operations
│
├── widgets/
│   ├── summary_card.dart            # Income/Expense card
│   ├── balance_card.dart            # Balance display card
│   ├── largest_expense_card.dart    # Largest expense card
│   └── empty_state.dart             # Empty state widget
│
└── main.dart                         # App entry point & Hive init
```
