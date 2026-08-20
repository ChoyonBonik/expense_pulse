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
  IntColumn get icon => integer().withDefault(const Constant(0))();
}

class Budgets extends Table {
  // Primary key
  IntColumn get id => integer().autoIncrement()();
  // Year and month of the budget (e.g., 2026, 8)
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  // Optional foreign key to a category; null means overall budget
  IntColumn get categoryId => integer().nullable().customConstraint('REFERENCES categories(id)')();
  // Budget amount
  RealColumn get amount => real()();
}


@DriftDatabase(tables: [Expenses, Incomes, Categories, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Insert methods for expenses and incomes
  Future<int> insertExpense(ExpensesCompanion expense) => into(expenses).insert(expense);
  Future<int> insertIncome(IncomesCompanion income) => into(incomes).insert(income);

  @override
  int get schemaVersion => 9;

  // Export DAO methods
  Future<List<Expense>> getAllExpenses() => select(expenses).get();
  Future<List<Income>> getAllIncomes() => select(incomes).get();
  Future<List<Category>> getAllCategories() => select(categories).get();
  Stream<List<Category>> watchAllCategories() => select(categories).watch();
  Future<List<Budget>> getAllBudgets() => select(budgets).get();

  Stream<List<Budget>> watchAllBudgets() => select(budgets).watch();
  Future<int> insertBudget(BudgetsCompanion budget) =>
      into(budgets).insert(budget);
  Future<int> upsertBudget(BudgetsCompanion budget) =>
      into(budgets).insertOnConflictUpdate(budget);
  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((t) => t.id.equals(id))).go();
  Future<Budget?> getOverallBudget(int year, int month) => (select(budgets)
          ..where((t) => t.year.equals(year) & t.month.equals(month) & t.categoryId.isNull()))
      .getSingleOrNull();
  Future<Budget?> getCategoryBudget(int year, int month, int catId) => (select(budgets)
          ..where((t) => t.year.equals(year) & t.month.equals(month) & t.categoryId.equals(catId)))
      .getSingleOrNull();
  Stream<List<Budget>> watchBudgetsByMonth(int year, int month) => (select(budgets)
          ..where((t) => t.year.equals(year) & t.month.equals(month)))
      .watch();

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
      if (from == 7) {
        await m.addColumn(categories, categories.icon);
      }
      if (from < 9) {
        await m.createTable(budgets);
      }
    },
  );


// Duplicate migration removed

  // DAO methods
  // Category DAO methods
  Future<int> insertCategory(CategoriesCompanion category) => into(categories).insert(category);
  Future<int> deleteCategory(int id) => (delete(categories)..where((t) => t.id.equals(id))).go();
  Future<bool> updateCategory(CategoriesCompanion category) => update(categories).replace(category);
  // Stream<List<Category>> watchAllCategories() => select(categories).watch();

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
