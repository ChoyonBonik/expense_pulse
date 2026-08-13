// lib/screens/add_entry_screen.dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth.dart';
import '../database/database.dart';
import '../providers.dart';

/// A combined screen for adding either an expense or an income.
///
/// The UI uses a tab bar with two tabs – **Expense** and **Income** – and reuses
/// the existing form logic from the separate screens. This keeps the code DRY
/// while giving the user a convenient single entry point.
class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Entry'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.money_off), text: 'Expense'),
              Tab(icon: Icon(Icons.attach_money), text: 'Income'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ExpenseForm(),
            _IncomeForm(),
          ],
        ),
      ),
    );
  }
}

/// ---------- Expense Form ----------
class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({super.key});

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Misc';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Misc',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.parse(_amountController.text);
    final auth = ref.read(authProvider);
    final username = auth.username;
    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }
    final expense = ExpensesCompanion(
      amount: Value(amount),
      category: Value(_selectedCategory),
      date: Value(_selectedDate),
      note: Value(_noteController.text.isEmpty ? null : _noteController.text),
      user: Value(username),
    );
    await ref.read(appDatabaseProvider).insertExpense(expense);
    if (mounted) context.pop(); // go back to previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : (double.tryParse(v) == null ? 'Enter a valid number' : null),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'Misc'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Save Expense'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Income Form ----------
class _IncomeForm extends ConsumerStatefulWidget {
  const _IncomeForm({super.key});

  @override
  ConsumerState<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<_IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.parse(_amountController.text);
    final source = _sourceController.text.trim();
    final auth = ref.read(authProvider);
    final username = auth.username;
    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }
    final income = IncomesCompanion(
      amount: Value(amount),
      source: Value(source),
      date: Value(_selectedDate),
      note: Value(_noteController.text.isEmpty ? null : _noteController.text),
      user: Value(username),
    );
    await ref.read(appDatabaseProvider).insertIncome(income);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : (double.tryParse(v) == null ? 'Enter a valid number' : null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter source' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Save Income'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
