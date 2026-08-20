// lib/app.dart
import 'package:expense_pulse/router/go_router_refresh_stream.dart';
import 'package:expense_pulse/screens/add_entry_screen.dart';
import 'package:expense_pulse/screens/category_screen.dart';
import 'package:expense_pulse/screens/category_settings_screen.dart';
import 'package:expense_pulse/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed hide import; GoRouterRefreshStream is now accessible via the standard import
import 'package:go_router/go_router.dart';
import 'screens/budget_screen.dart';
import 'screens/export_screen.dart';
import 'providers.dart';
import 'auth/auth.dart';
import 'screens/home_screen.dart';

import 'screens/register_screen.dart';
import 'screens/edit_expense_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

class ExpensePulseApp extends ConsumerWidget {
  const ExpensePulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
    initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final loggingIn = state.matchedLocation == '/login';
        final registering = state.matchedLocation == '/register';
        if (auth.status == AuthStatus.unauthenticated && !loggingIn && !registering) {
          return '/login';
        }
        if (auth.status == AuthStatus.authenticated && (loggingIn || registering)) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        // Updated routes: unified add entry screen
        GoRoute(path: '/add', builder: (context, state) => const CategoryScreen()),
        GoRoute(path: '/add_entry', builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          final typeStr = state.uri.queryParameters['type'];
          final type = typeStr != null ? int.tryParse(typeStr) : null;
          return AddEntryScreen(initialCategory: category, initialType: type);
        }),
        // Removed separate add-income route

        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

        
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        GoRoute(path: '/categories/settings', builder: (context, state) => const CategorySettingsScreen()),
        GoRoute(path: '/export', builder: (context, state) => const ExportScreen()),
        GoRoute(path: '/budget', builder: (context, state) => const BudgetScreen()),
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        GoRoute(
          path: '/edit/:id',
          builder: (context, state) => EditExpenseScreen(
            expenseId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'ExpensePulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ref.watch(themeProvider),
      routerConfig: router,
    );
  }
}



