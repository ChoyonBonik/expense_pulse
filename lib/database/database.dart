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

@DriftDatabase(tables: [Expenses, Incomes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // Added 'user' column (nullable) in version 2
        await m.addColumn(expenses, expenses.user);
      }
      if (from < 3) {
        // Added Incomes table in version 3
        await m.createTable(incomes);
      }
    },
  );

  // DAO methods
  Future<int> insertExpense(Insertable<Expense> expense) => into(expenses).insert(expense);
  Future<int> insertIncome(Insertable<Income> income) => into(incomes).insert(income);
  Stream<List<Expense>> watchExpensesByUser(String username) =>
      (select(expenses)..where((t) => t.user.equals(username))).watch();
  Stream<List<Income>> watchIncomesByUser(String username) =>
      (select(incomes)..where((t) => t.user.equals(username))).watch();
  Future<int> deleteExpense(int id) => (delete(expenses)..where((t) => t.id.equals(id))).go();
  Future<int> deleteIncome(int id) => (delete(incomes)..where((t) => t.id.equals(id))).go();
  Future<bool> updateExpense(Insertable<Expense> expense) => update(expenses).replace(expense);
  Future<bool> updateIncome(Insertable<Income> income) => update(incomes).replace(income);
  Future<Expense?> getExpenseById(int id) => (select(expenses)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<Income?> getIncomeById(int id) => (select(incomes)..where((t) => t.id.equals(id))).getSingleOrNull();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expense_pulse.sqlite'));
    return NativeDatabase(file);
  });
}
