// lib/screens/export_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:share_plus/share_plus.dart';

import '../providers.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final expenses = await ref.read(appDatabaseProvider).getAllExpenses();
    final incomes = await ref.read(appDatabaseProvider).getAllIncomes();
    final categories = await ref.read(appDatabaseProvider).getAllCategories();
    final budgets = await ref.read(appDatabaseProvider).getAllBudgets();
    // Build a quick lookup for category names by id
    final Map<int, String> categoryIdToName = { for (var c in categories) c.id: c.name };


    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context c) {
          return pw.Column(
            children: [
              pw.Text('Expenses', style: pw.TextStyle(fontSize: 24)),
              pw.Table.fromTextArray(
                headers: ['ID', 'Amount', 'Category', 'Date', 'Note'],
                data: expenses
                    .map(
                      (e) => [
                        e.id,
                        e.amount,
                        e.category,
                        e.date.toString(),
                        e.note ?? '',
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Incomes', style: pw.TextStyle(fontSize: 24)),
              pw.Table.fromTextArray(
                headers: ['ID', 'Amount', 'Source', 'Date', 'Note'],
                data: incomes
                    .map(
                      (i) => [
                        i.id,
                        i.amount,
                        i.source,
                        i.date.toString(),
                        i.note ?? '',
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Categories', style: pw.TextStyle(fontSize: 24)),
              pw.Table.fromTextArray(
                headers: ['ID', 'Name', 'Type', 'Icon'],
                data: categories
                    .map((c) => [c.id, c.name, c.type, c.icon])
                    .toList(),
              ),
              pw.SizedBox(height: 20),
               // Budgets section
               pw.Text('Budgets', style: pw.TextStyle(fontSize: 24)),
               pw.Table.fromTextArray(
                 headers: ['ID', 'Year', 'Month', 'Category', 'Amount'],
                 data: budgets
                     .map(
                       (b) => [
                         b.id,
                         b.year,
                         b.month,
                         b.categoryId != null ? (categoryIdToName[b.categoryId!] ?? 'Unknown') : 'Overall',
                         b.amount,
                       ],
                     )
                     .toList(),
               ),
            ],
          );
        },
      ),
    );

    // Save to temporary directory
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/expense_data_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    // Share the file
    await Share.shareXFiles([XFile(file.path)], text: 'Here is your PDF');
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final expenses = await ref.read(appDatabaseProvider).getAllExpenses();
    final incomes = await ref.read(appDatabaseProvider).getAllIncomes();
    final categories = await ref.read(appDatabaseProvider).getAllCategories();

    final excel = ex.Excel.createExcel();
    var expSheet = excel['Expenses'];
    expSheet.appendRow(['ID', 'Amount', 'Category', 'Date', 'Note']);
    for (var e in expenses) {
      expSheet.appendRow([
        e.id,
        e.amount,
        e.category,
        e.date.toString(),
        e.note ?? '',
      ]);
    }
    final incSheet = excel['Incomes'];
    incSheet.appendRow(['ID', 'Amount', 'Source', 'Date', 'Note']);
    for (var i in incomes) {
      incSheet.appendRow([
        i.id,
        i.amount,
        i.source,
        i.date.toString(),
        i.note ?? '',
      ]);
    }
    final catSheet = excel['Categories'];
    catSheet.appendRow(['ID', 'Name', 'Type', 'Icon']);
    for (var c in categories) {
      catSheet.appendRow([c.id, c.name, c.type, c.icon]);
    }

    // Save to temporary directory
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/expense_data_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);

    // Share the file
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Here is your Excel file');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => _exportPdf(context, ref),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export as PDF'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _exportExcel(context, ref),
              icon: const Icon(Icons.table_chart),
              label: const Text('Export as Excel'),
            ),
          ],
        ),
      ),
    );
  }
}
