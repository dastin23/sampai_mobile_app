import 'package:flutter/material.dart';

import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/liquid_glass.dart';
import '../add_expense/add_expense_sheet.dart';
import '../budget/budget_controller.dart';
import '../budget/budget_screen.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';
import '../profil/profil_screen.dart';
import '../transactions/transactions_controller.dart';
import '../transactions/transactions_screen.dart';

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
  late final TransactionsController _transactionsController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(widget.appState)..load();
    _budgetController = BudgetController(widget.appState)..load();
    _transactionsController = TransactionsController(widget.appState)..load();
  }

  @override
  void dispose() {
    _homeController.dispose();
    _budgetController.dispose();
    _transactionsController.dispose();
    super.dispose();
  }

  void _goTo(int index) => setState(() => _index = index);

  Future<void> _openAddExpense() async {
    final saved = await showAddExpenseSheet(context, appState: widget.appState);
    if (saved == null || !mounted) return;
    widget.appState.addTransaction(saved);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pengeluaran tersimpan')),
      );
  }

  Future<void> _openAddIncome() async {
    final saved = await showAddIncomeSheet(context, appState: widget.appState);
    if (saved == null || !mounted) return;
    widget.appState.addTransaction(saved);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pemasukan tersimpan')),
      );
  }

  Future<void> _openEditTransaction(ExpenseTransaction transaction) async {
    final isIncome = transaction.isIncome;
    final result = await showEditTransactionSheet(
      context,
      appState: widget.appState,
      transaction: transaction,
    );
    if (result == null || !mounted) return;
    final noun = isIncome ? 'Pemasukan' : 'Pengeluaran';
    final message = switch (result.action) {
      TransactionSheetAction.deleted => '$noun dihapus',
      TransactionSheetAction.saved => '$noun diperbarui',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AtmosphereBackground(
        child: SafeArea(
          child: switch (_index) {
            0 => HomeScreen(
                controller: _homeController,
                onAddExpense: _openAddExpense,
                onAddIncome: _openAddIncome,
                onSeeAllBudgets: () => _goTo(1),
                onSeeAllTransactions: () => _goTo(2),
                onRestartOnboarding: widget.onRestartOnboarding,
              ),
            1 => BudgetScreen(controller: _budgetController),
            2 => TransactionsScreen(
                controller: _transactionsController,
                onAddExpense: _openAddExpense,
                onAddIncome: _openAddIncome,
                onEditTransaction: _openEditTransaction,
              ),
            _ => ProfilScreen(
                appState: widget.appState,
                onRestartOnboarding: widget.onRestartOnboarding,
              ),
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassSurface(
          kind: GlassKind.chrome,
          radius: AppSpacing.dockRadius,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
        ),
      ),
    );
  }
}
