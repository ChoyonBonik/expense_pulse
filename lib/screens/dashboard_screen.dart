// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers.dart';
import '../database/database.dart';

/// Dashboard with two tabs: Expenses and Income.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both streams – they will be used inside the tab views.
    final expensesAsync = ref.watch(userExpensesStreamProvider);
    final incomesAsync = ref.watch(userIncomesStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.money_off), text: 'Expenses'),
              Tab(icon: Icon(Icons.attach_money), text: 'Income'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Expenses tab
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (expenses) => _ExpenseTab(expenses: expenses),
            ),
            // Income tab
            incomesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (incomes) => _IncomeTab(incomes: incomes),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that renders the expense view (previous implementation).
class _ExpenseTab extends ConsumerWidget {
  final List<Expense> expenses;
  const _ExpenseTab({required this.expenses, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthExpenses = expenses.where((e) => e.date.year == now.year && e.date.month == now.month);
    final total = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    // Category breakdown for the pie chart
    final Map<String, double> categoryMap = {};
    for (var e in monthExpenses) {
      categoryMap.update(e.category, (value) => value + e.amount, ifAbsent: () => e.amount);
    }
    final List<PieChartSectionData> sections = [];
    final colors = [Colors.teal, Colors.orange, Colors.purple, Colors.blue, Colors.red, Colors.green];
    int i = 0;
    categoryMap.forEach((cat, amt) {
      final percent = total == 0 ? 0 : (amt / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: amt,
          title: '${percent.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      i++;
    });

    // Recent 5 expenses
    final recent = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentFive = recent.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total this month: ${NumberFormat.currency(symbol: "৳").format(total)}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Builder(builder: (context) {
              final expenseTotal = total;
              final budgetsAsync = ref.watch(monthBudgetsProvider);
              return budgetsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error loading budgets: $e'),
                data: (budgets) {
                  final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.amount);
                  final remaining = totalBudget - expenseTotal;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget this month: ${NumberFormat.currency(symbol: "৳").format(totalBudget)}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Remaining: ${NumberFormat.currency(symbol: "৳").format(remaining)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: remaining >= 0 ? Colors.green : Colors.red)),
                    ],
                  );
                },
              );
            }),
          ),
          if (sections.isNotEmpty)
            SizedBox(height: 250, child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40, borderData: FlBorderData(show: false))))
          else
            const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('No expenses for this month.'))),
          const Divider(),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentFive.length,
            itemBuilder: (context, index) {
              final e = recentFive[index];
              return ListTile(
                leading: CircleAvatar(child: Text(e.category[0].toUpperCase())),
                title: Text(NumberFormat.currency(symbol: "৳").format(e.amount)),
                subtitle: Text('${e.category} • ${DateFormat.yMMMd().format(e.date)}'),
                trailing: const Icon(Icons.chevron_right),
                // onTap: () => context.push('/edit/${e.id}'),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget that renders the income view.
class _IncomeTab extends StatelessWidget {
  final List<Income> incomes;
  const _IncomeTab({required this.incomes, super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthIncomes = incomes.where((i) => i.date.year == now.year && i.date.month == now.month);
    final total = monthIncomes.fold<double>(0, (sum, i) => sum + i.amount);

    // Source breakdown for the pie chart
    final Map<String, double> sourceMap = {};
    for (var i in monthIncomes) {
      sourceMap.update(i.source, (value) => value + i.amount, ifAbsent: () => i.amount);
    }
    final List<PieChartSectionData> sections = [];
    final colors = [Colors.green, Colors.lightGreen, Colors.blue, Colors.indigo, Colors.teal];
    int i = 0;
    sourceMap.forEach((src, amt) {
      final percent = total == 0 ? 0 : (amt / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: amt,
          title: '${percent.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      i++;
    });

    // Recent 5 incomes
    final recent = List<Income>.from(incomes)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentFive = recent.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total income this month: ${NumberFormat.currency(symbol: "৳").format(total)}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          if (sections.isNotEmpty)
            SizedBox(height: 250, child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40, borderData: FlBorderData(show: false))))
          else
            const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('No income for this month.'))),
          const Divider(),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text('Recent Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentFive.length,
            itemBuilder: (context, index) {
              final i = recentFive[index];
              return ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(NumberFormat.currency(symbol: "৳").format(i.amount)),
                subtitle: Text('${i.source} • ${DateFormat.yMMMd().format(i.date)}'),
                trailing: const Icon(Icons.chevron_right),
                // onTap: () => context.push('/edit_income/${i.id}'), // assumes you have an edit route for income
              );
            },
          ),
        ],
      ),
    );
  }
}
