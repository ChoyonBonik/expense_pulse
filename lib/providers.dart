// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'auth/auth.dart';
import 'database/database.dart';

// Theme mode provider (light/dark/system)
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Provide a singleton instance of the Drift database
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Stream of expenses from the database
final userExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.username == null) return const Stream.empty();
  return ref.watch(appDatabaseProvider).watchExpensesByUser(auth.username!);
});

// Stream of incomes for the logged-in user
final userIncomesStreamProvider = StreamProvider<List<Income>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.username == null) return const Stream.empty();
  return ref.watch(appDatabaseProvider).watchIncomesByUser(auth.username!);
});
