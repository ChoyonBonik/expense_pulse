// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../auth/auth.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(userExpensesStreamProvider);
    final incomesAsync = ref.watch(userIncomesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ExpensePulse')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text('ExpensePulse', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => context.go('/'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Expense'),
              onTap: () => context.push('/add'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Add Income'),
              onTap: () => context.push('/add-income'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => context.push('/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => context.push('/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(authProvider.notifier).logout();
                  // GoRouter redirect will handle navigation to login
                }
              },
            ),
          ],
        ),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          return incomesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (incomes) {
              final expenseTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);
              final incomeTotal = incomes.fold<double>(0, (sum, i) => sum + i.amount);
              final net = incomeTotal - expenseTotal;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income this month: ${NumberFormat.currency(symbol: "৳").format(incomeTotal)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expense this month: ${NumberFormat.currency(symbol: "৳").format(expenseTotal)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Net balance: ${NumberFormat.currency(symbol: "৳").format(net)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: net >= 0 ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: expenses.isEmpty
                        ? const Center(child: Text('No expenses yet.'))
                        : ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final e = expenses[index];
                              return Dismissible(
                                key: ValueKey(e.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) async {
                                  await ref.read(appDatabaseProvider).deleteExpense(e.id);
                                },
                                child: ListTile(
                                  onTap: () => context.push('/edit/${e.id}'),
                                  onLongPress: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete expense'),
                                        content: const Text('Are you sure you want to delete this expense?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(appDatabaseProvider).deleteExpense(e.id);
                                    }
                                  },
                                  leading: CircleAvatar(child: Text(e.category[0].toUpperCase())),
                                  title: Text(NumberFormat.currency(symbol: "৳").format(e.amount)),
                                  subtitle: Text('${e.category} • ${DateFormat.yMMMd().format(e.date)}'),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
        ],
        onTap: (index) {
          if (index == 0) context.go('/');
          else if (index == 1) context.push('/add');
          else if (index == 2) context.go('/dashboard');
        },
      ),
    );
  }
}
