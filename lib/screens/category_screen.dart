// lib/screens/category_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth.dart';
import '../database/database.dart';
import 'package:drift/drift.dart' hide Column;

import '../providers.dart';
import 'package:go_router/go_router.dart';

// List of selectable icons for custom categories
const List<IconData> _categoryIcons = [
  Icons.shopping_cart,
  Icons.fastfood,
  Icons.phone_android,
  Icons.movie,
  Icons.school,
  Icons.brush,
  Icons.sports_soccer,
  Icons.people,
  Icons.directions_car,
  Icons.flight,
  Icons.favorite,
  Icons.home,
  Icons.category,
];

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Category Settings',
              onPressed: () => context.push('/categories/settings'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: categoriesAsync.when(
          data: (categories) {
            // Default hard‑coded categories (shown initially)
            final defaultCategories = [
              Category(id: 0, name: 'Shopping', type: 0, icon: 1),
              Category(id: 0, name: 'Food', type: 0, icon: 2),
              Category(id: 0, name: 'Phone', type: 0, icon: 3),
              Category(id: 0, name: 'Entertainment', type: 0, icon: 4),
              Category(id: 0, name: 'Education', type: 0, icon: 5),
              Category(id: 0, name: 'Beauty', type: 0, icon: 6),
              Category(id: 0, name: 'Sports', type: 0, icon: 7),
              Category(id: 0, name: 'Social', type: 0, icon: 8),
              Category(id: 0, name: 'Car', type: 0, icon: 9),
              Category(id: 0, name: 'Travel', type: 0, icon: 10),
              Category(id: 0, name: 'Health', type: 0, icon: 11),
              Category(id: 0, name: 'Home', type: 0, icon: 12),
            ];
            final all = [...categories, ...defaultCategories];
            return TabBarView(
              children: [
                _buildCategoryGrid(context, ref, all, 1), // Expense tab
                _buildCategoryGrid(context, ref, all, 2), // Income tab
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, WidgetRef ref, List<Category> allCategories, int filterType) {
    final filtered = filterType == 0
        ? allCategories
        : allCategories.where((c) => c.type == filterType || c.type == 0).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final cat = filtered[index];
        return GestureDetector(
          onTap: () {
            // Show add entry dialog instead of navigating
            _showAddEntryDialog(context, ref, cat, filterType);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconForCategory(cat), size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(cat.name,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(_typeLabel(cat.type),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  String _typeLabel(int type) {
    switch (type) {
      case 0:
        return 'Both';
      case 1:
        return 'Expense';
      case 2:
        return 'Income';
      default:
        return 'Unknown';
    }
  }

  // Returns icon based on store mapping if needed
  IconData _iconForCategory(Category cat) {
    if (cat.icon != null && cat.icon > 0 && cat.icon <= _categoryIcons.length) {
      return _categoryIcons[cat.icon - 1];
    }
    // Fallback based on name
    switch (cat.name.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_cart;
      case 'food':
        return Icons.fastfood;
      case 'phone':
        return Icons.phone_android;
      case 'entertainment':
        return Icons.movie;
      case 'education':
        return Icons.school;
      case 'beauty':
        return Icons.brush;
      case 'sports':
        return Icons.sports_soccer;
      case 'social':
        return Icons.people;
      case 'car':
        return Icons.directions_car;
      case 'travel':
        return Icons.flight;
      case 'health':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      default:
        return Icons.category;
    }
  }




}

Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  int selectedType = 0;
  int selectedIcon = 1;
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Both')),
                DropdownMenuItem(value: 1, child: Text('Expense')),
                DropdownMenuItem(value: 2, child: Text('Income')),
              ],
              onChanged: (v) => setState(() => selectedType = v ?? 0),
            ),
            const SizedBox(height: 12),
            // Icon selector
            DropdownButtonFormField<int>(
              value: selectedIcon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: List.generate(_categoryIcons.length, (i) => DropdownMenuItem(
                value: i + 1,
                child: Row(
                  children: [
                    Icon(_categoryIcons[i]),
                    const SizedBox(width: 8),
                    Text('Icon ${i + 1}'),
                  ],
                ),
              )),
              onChanged: (v) => setState(() => selectedIcon = v ?? 1),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final category = CategoriesCompanion(
                name: Value(name),
                type: Value(selectedType),
                icon: Value(selectedIcon),
              );
              await ref.read(appDatabaseProvider).insertCategory(category);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
// Show a popup to quickly add an entry (expense or income) without navigating away.
Future<void> _showAddEntryDialog(
    BuildContext context, WidgetRef ref, Category cat, int filterType) async {
  final amountController = TextEditingController();
  final titleController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(filterType == 1 ? 'Add Expense' : 'Add Income'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                selectedDate = picked;
                (ctx as Element).markNeedsBuild();
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final amountText = amountController.text.trim();
            final title = titleController.text.trim();
            if (amountText.isEmpty || title.isEmpty) return;
            final amount = double.tryParse(amountText);
            if (amount == null) return;
            final username = ref.read(authProvider).username;
            if (username == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not logged in.')),
              );
              return;
            }
            if (filterType == 1) {
              // Expense
              await ref.read(appDatabaseProvider).insertExpense(
                ExpensesCompanion(
                  amount: Value(amount),
                  category: Value(cat.name),
                  date: Value(selectedDate),
                  note: Value(title),
                  user: Value(username),
                ),
              );
            } else {
              // Income
              await ref.read(appDatabaseProvider).insertIncome(
                IncomesCompanion(
                  amount: Value(amount),
                  source: Value(cat.name),
                  date: Value(selectedDate),
                  note: const Value(null),
                  user: Value(username),
                ),
              );
            }
            Navigator.of(ctx).pop();
            context.go('/');
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
