// lib/screens/category_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'package:drift/drift.dart' hide Column;

import '../providers.dart';
import 'package:go_router/go_router.dart';

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
              Category(id: 0, name: 'Shopping', type: 0),
              Category(id: 0, name: 'Food', type: 0),
              Category(id: 0, name: 'Phone', type: 0),
              Category(id: 0, name: 'Entertainment', type: 0),
              Category(id: 0, name: 'Education', type: 0),
              Category(id: 0, name: 'Beauty', type: 0),
              Category(id: 0, name: 'Sports', type: 0),
              Category(id: 0, name: 'Social', type: 0),
              Category(id: 0, name: 'Car', type: 0),
              Category(id: 0, name: 'Travel', type: 0),
              Category(id: 0, name: 'Health', type: 0),
              Category(id: 0, name: 'Home', type: 0),
            ];
            final all = [...categories, ...defaultCategories];
            return TabBarView(
              children: [
                _buildCategoryGrid(context, all, 1), // Expense tab
                _buildCategoryGrid(context, all, 2), // Income tab
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> allCategories, int filterType) {
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
              // Navigate based on the selected tab (filterType)
              if (filterType == 1) {
                // Expense tab
                context.go('/add_entry?category=${Uri.encodeComponent(cat.name)}&type=1');
              } else if (filterType == 2) {
                // Income tab
                context.go('/add_entry?category=${Uri.encodeComponent(cat.name)}&type=2');
              }
            },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconForCategory(cat.name), size: 36, color: Colors.white),
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

  IconData _iconForCategory(String name) {
    switch (name.toLowerCase()) {
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
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
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
            onChanged: (v) => selectedType = v ?? 0,
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
            );
            await ref.read(appDatabaseProvider).insertCategory(category);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
