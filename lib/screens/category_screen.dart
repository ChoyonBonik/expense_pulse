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
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
                title: Text(cat.name),
                subtitle: Text(_typeLabel(cat.type)),
                onTap: () {
                  // Determine navigation based on category type
                  if (cat.type == 1) {
                    // Expense only
                    context.go('/add_entry?category=${Uri.encodeComponent(cat.name)}&type=1');
                  } else if (cat.type == 2) {
                    // Income only
                    context.go('/add_entry?category=${Uri.encodeComponent(cat.name)}&type=2');
                  } else {
                    // Both - ask user which
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Select Entry Type'),
                        content: const Text('Do you want to add an expense or income?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(c).pop();
                              context.go('/add_entry?category=${Uri.encodeComponent(cat.name)}&type=1');
                            },
                            child: const Text('Expense'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(c).pop();
                              context.go('/add_entry?category=${Uri.encodeComponent(cat.name)}&type=2');
                            },
                            child: const Text('Income'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Add Category',
      ),
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
