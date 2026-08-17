// lib/database/database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get source => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get user => text().nullable()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get user => text().nullable()();
}

// New Category table for both expense and income categories
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // type: 0 = both, 1 = expense only, 2 = income only
  IntColumn get type => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Expenses, Incomes, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Insert methods for expenses and incomes
  Future<int> insertExpense(ExpensesCompanion expense) => into(expenses).insert(expense);
  Future<int> insertIncome(IncomesCompanion income) => into(incomes).insert(income);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        await m.addColumn(expenses, expenses.user);
      }
      if (from < 3) {
        await m.createTable(incomes);
      }
      if (from < 6) {
        await m.createTable(categories);
      }
    },
  );

// Duplicate migration removed

  // DAO methods
  // Category DAO methods
  Future<int> insertCategory(CategoriesCompanion category) => into(categories).insert(category);
  Future<int> deleteCategory(int id) => (delete(categories)..where((t) => t.id.equals(id))).go();
  Future<bool> updateCategory(CategoriesCompanion category) => update(categories).replace(category);
  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  // Expense/Income DAO methods
  Stream<List<Expense>> watchExpensesByUser(String username) => (select(expenses)..where((t) => t.user.equals(username))).watch();
  Stream<List<Income>> watchIncomesByUser(String username) => (select(incomes)..where((t) => t.user.equals(username))).watch();
  Future<int> deleteExpense(int id) => (delete(expenses)..where((t) => t.id.equals(id))).go();
  Future<int> deleteIncome(int id) => (delete(incomes)..where((t) => t.id.equals(id))).go();
  Future<bool> updateExpense(Insertable<Expense> expense) => update(expenses).replace(expense);

  Future<Income?> getIncomeById(int id) => (select(incomes)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<Expense?> getExpenseById(int id) => (select(expenses)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<bool> updateIncome(Insertable<Income> income) => update(incomes).replace(income);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expense_pulse.sqlite'));
    return NativeDatabase(file);
  });
}
