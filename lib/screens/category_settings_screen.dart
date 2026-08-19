// lib/screens/category_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers.dart';

// List of selectable icons (same as in category_screen.dart)
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

class CategorySettingsScreen extends ConsumerWidget {
  const CategorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Category Settings')),
      body: categoriesAsync.when(
        data: (categories) => ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: Icon(_iconForCategory(cat)),
              title: Text(cat.name),
              subtitle: Text(_typeLabel(cat.type)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, ref, cat),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(ref, cat.id),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading categories: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context, ref),
      ),
    );
  }

  // Helper UI utilities (duplicate of those in category_screen.dart)
  IconData _iconForCategory(Category cat) {
    if (cat.icon > 0 && cat.icon <= _categoryIcons.length) {
      return _categoryIcons[cat.icon - 1];
    }
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

  void _deleteCategory(WidgetRef ref, int id) async {
    await ref.read(appDatabaseProvider).deleteCategory(id);
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    int selectedType = 0;
    int selectedIcon = 1;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
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
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedIcon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: List.generate(
                _categoryIcons.length,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Row(
                    children: [
                      Icon(_categoryIcons[i]),
                      const SizedBox(width: 8),
                      Text('Icon ${i + 1}'),
                    ],
                  ),
                ),
              ),
              onChanged: (v) => selectedIcon = v ?? 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final cat = CategoriesCompanion(
                name: Value(name),
                type: Value(selectedType),
                icon: Value(selectedIcon),
              );
              await ref.read(appDatabaseProvider).insertCategory(cat);
              if (c.mounted) Navigator.of(c).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, Category cat) async {
    final nameCtrl = TextEditingController(text: cat.name);
    int selectedType = cat.type;
    int selectedIcon = cat.icon;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
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
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedIcon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: List.generate(
                _categoryIcons.length,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Row(
                    children: [
                      Icon(_categoryIcons[i]),
                      const SizedBox(width: 8),
                      Text('Icon ${i + 1}'),
                    ],
                  ),
                ),
              ),
              onChanged: (v) => selectedIcon = v ?? 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final updated = CategoriesCompanion(
                id: Value(cat.id),
                name: Value(name),
                type: Value(selectedType),
                icon: Value(selectedIcon),
              );
              await ref.read(appDatabaseProvider).updateCategory(updated);
              if (c.mounted) Navigator.of(c).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
