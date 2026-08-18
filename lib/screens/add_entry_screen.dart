import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth.dart'; // added auth import
import '../providers.dart';
import 'package:drift/drift.dart' as drift; // prefixed drift import
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;

/// Screen for adding either an expense or an income.
class AddEntryScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final int? initialType; // 1 = expense, 2 = income
  const AddEntryScreen({super.key, this.initialCategory, this.initialType});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

DateTime _selectedDate = DateTime.now();
String _selectedCategory = 'Misc';

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  @override
  void initState() {
    super.initState();
    // Pre‑select category passed from CategoryScreen if any
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    // Provider update for consistency with other screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCategoryProvider.notifier).state = _selectedCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine initial tab index: 0 for expense, 1 for income
    int initialIndex = 0;
    if (widget.initialType == 2) {
      initialIndex = 1;
    }
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
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
        body: const TabBarView(children: [_ExpenseForm(), _IncomeForm()]),
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
  @override
  void initState() {
    super.initState();
    // If a category was preselected via navigation, initialize state accordingly.
    final preselected = ref.read(selectedCategoryProvider);
    if (preselected != null) {
      _selectedCategory = preselected;
      // Show number pad automatically for amount entry.
      _showNumberPad = true;
      _numberPadAtTop = false; // start at bottom
    }
  }

  // Number pad visibility and position
  bool _showNumberPad = false;
  bool _numberPadAtTop = false; // false => bottom, true => top

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Number pad helpers
  void _appendDigit(String digit) {
    _amountController.text = _amountController.text + digit;
  }

  void _deleteLast() {
    final text = _amountController.text;
    if (text.isNotEmpty) {
      _amountController.text = text.substring(0, text.length - 1);
    }
  }

  Widget _buildNumberPad() {
    const buttons = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '0',
      '⌫',
      '✓',
    ];
    return Align(
      alignment: _numberPadAtTop ? Alignment.topCenter : Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showNumberPad ? 250 : 0,
        color: Colors.grey[200],
        child: GridView.count(
          crossAxisCount: 3,
          children: buttons
              .map(
                (label) => InkWell(
                  onTap: () {
                    if (label == '⌫')
                      _deleteLast();
                    else if (label == '✓') {
                      // Submit the entry and navigate to home screen
                      _submit();
                      // After submission, navigate to home (root) to display updated list
                      context.go('/');
                    } else
                      _appendDigit(label);
                  },
                  child: Center(
                    child: Text(label, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // Add Category dialog (kept from original implementation)
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    int type = 0; // 0 = both, 1 = expense, 2 = income
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: type,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Both')),
                DropdownMenuItem(value: 1, child: Text('Expense')),
                DropdownMenuItem(value: 2, child: Text('Income')),
              ],
              onChanged: (v) => type = v ?? 0,
              decoration: const InputDecoration(labelText: 'Type'),
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await ref
                    .read(appDatabaseProvider)
                    .insertCategory(
                      CategoriesCompanion(
                        name: drift.Value(name),
                        type: drift.Value(type),
                      ),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }
    final expense = ExpensesCompanion(
      amount: drift.Value(amount),
      category: drift.Value(_selectedCategory),
      date: drift.Value(_selectedDate),
      note: drift.Value(
        _noteController.text.isEmpty ? null : _noteController.text,
      ),
      user: drift.Value(username),
    );
    await ref.read(appDatabaseProvider).insertExpense(expense);
  }

  @override
  Widget build(BuildContext context) {
    // Watch categories stream
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.when(
      data: (list) => list.map((c) => c.name).toList(),
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );

    // Ensure selected category is valid
    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _amountController,
                  readOnly: true,
                  onTap: () => setState(() {
                    _showNumberPad = true;
                    // Show number pad at bottom initially
                    _numberPadAtTop = false;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter amount'
                      : (double.tryParse(v) == null
                            ? 'Enter a valid number'
                            : null),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isNotEmpty
                      ? _selectedCategory
                      : null,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _selectedCategory = v ?? 'Misc';
                      // When a category is chosen, move number pad to top
                      _numberPadAtTop = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                  ),
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Number pad overlay (position controlled by _numberPadAtTop)
        if (_showNumberPad) _buildNumberPad(),
      ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }
    final income = IncomesCompanion(
      amount: drift.Value(amount),
      source: drift.Value(source),
      date: drift.Value(_selectedDate),
      note: drift.Value(
        _noteController.text.isEmpty ? null : _noteController.text,
      ),
      user: drift.Value(username),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Enter amount'
                  : (double.tryParse(v) == null
                        ? 'Enter a valid number'
                        : null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter source' : null,
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
