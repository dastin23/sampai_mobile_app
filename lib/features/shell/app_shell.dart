import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../budget/budget_controller.dart';
import '../budget/budget_screen.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';

/// Shell navigasi bawah: Home, Budget, Transaksi, Profil (PRD 5.2.G).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.appState,
    required this.onRestartOnboarding,
  });

  final AppState appState;
  final VoidCallback onRestartOnboarding;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final HomeController _homeController;
  late final BudgetController _budgetController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(widget.appState)..load();
    _budgetController = BudgetController(widget.appState)..load();
  }

  @override
  void dispose() {
    _homeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _goTo(int index) => setState(() => _index = index);

  void _showAddExpenseNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Layar Catat pengeluaran menyusul pada iterasi berikutnya.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: switch (_index) {
          0 => HomeScreen(
              controller: _homeController,
              onAddExpense: _showAddExpenseNotice,
              onSeeAllBudgets: () => _goTo(1),
              onSeeAllTransactions: () => _goTo(2),
              onRestartOnboarding: widget.onRestartOnboarding,
            ),
          1 => BudgetScreen(controller: _budgetController),
          2 => const _ComingSoonScreen(title: 'Transaksi'),
          _ => const _ComingSoonScreen(title: 'Profil'),
        },
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_small_outlined),
            selectedIcon: Icon(Icons.donut_small),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.h1),
          const SizedBox(height: AppSpacing.component),
          const Text(
            'Layar ini menyusul pada iterasi berikutnya.',
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }
}
