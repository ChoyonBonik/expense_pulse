// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'database/database.dart';

// Theme mode provider (light/dark/system)
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Provide a singleton instance of the Drift database
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Stream of expenses from the database
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(appDatabaseProvider).watchAllExpenses();
});
