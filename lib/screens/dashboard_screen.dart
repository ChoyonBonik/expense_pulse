// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers.dart';
import '../database/database.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          // Filter expenses for the current month
          final now = DateTime.now();
          final monthExpenses = expenses.where((e) =>
              e.date.year == now.year && e.date.month == now.month);

          final total = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

          // Compute category breakdown
          final Map<String, double> categoryMap = {};
          for (var e in monthExpenses) {
            categoryMap.update(e.category, (value) => value + e.amount,
                ifAbsent: () => e.amount);
          }

          // Prepare pie chart sections
          final List<PieChartSectionData> sections = [];
          final colors = [
            Colors.teal,
            Colors.orange,
            Colors.purple,
            Colors.blue,
            Colors.red,
            Colors.green,
          ];
          int i = 0;
          categoryMap.forEach((cat, amt) {
            final percent = total == 0 ? 0 : (amt / total) * 100;
            sections.add(
              PieChartSectionData(
                color: colors[i % colors.length],
                value: amt,
                title: '${percent.toStringAsFixed(1)}%',
                radius: 60,
                titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            );
            i++;
          });

          // Recent activity: last 5 expenses sorted by date descending
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
                if (sections.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No expenses for this month.')),
                  ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
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
                      onTap: () => context.push('/edit/${e.id}'),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
