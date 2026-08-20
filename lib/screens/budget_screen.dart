// lib/screens/budget_screen.dart
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_pulse/database/database.dart';
import '../providers.dart';


class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int? _selectedYear;
  int? _selectedMonth;
  Category? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || _selectedYear == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }
    final db = ref.read(appDatabaseProvider);
    final budgetCompanion = BudgetsCompanion(
      year: Value(_selectedYear!),
      month: Value(_selectedMonth!),
      categoryId: _selectedCategory != null ? Value(_selectedCategory!.id) : const Value.absent(),
      amount: Value(amount),
    );
    await db.upsertBudget(budgetCompanion);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget saved')),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Set Budget')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Year'),
              value: _selectedYear,
              items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                  .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                  .toList(),
              onChanged: (v) => setState(() => _selectedYear = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Month'),
              value: _selectedMonth,
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.toString())))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMonth = v),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error loading categories: $e'),
              data: (categories) => DropdownButtonFormField<Category?>(
                decoration: const InputDecoration(labelText: 'Category (optional)'),
                value: _selectedCategory,
                items: [
                  const DropdownMenuItem<Category?>(value: null, child: Text('Overall')),
                  ...categories.map((c) => DropdownMenuItem<Category?>(value: c, child: Text(c.name))),
                ],
                onChanged: (c) => setState(() => _selectedCategory = c),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveBudget,
              child: const Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
