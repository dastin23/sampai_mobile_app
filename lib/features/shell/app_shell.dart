import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/liquid_glass.dart';
import '../budget/budget_screen.dart';
import '../home/home_screen.dart';
import '../profil/profil_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/widgets/transaction_editor_sheet.dart';

/// Shell navigasi bawah: Home, Budget, Transaksi, Profil (PRD 5.2.G).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.appState,
    required this.onRestartOnboarding,
    this.displayName,
    this.userEmail,
  });

  final AppState appState;
  final VoidCallback onRestartOnboarding;

  /// Nama tampilan pengguna (null bila tidak tersedia).
  final String? displayName;

  /// Email pengguna (null bila tidak tersedia).
  final String? userEmail;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  Future<void> _openAddExpense() async {
    final result = await showTransactionEditorSheet(context, type: 'expense');
    if (result != TransactionEditorResult.saved || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pengeluaran tersimpan')),
      );
  }

  Future<void> _openAddIncome() async {
    final result = await showTransactionEditorSheet(context, type: 'income');
    if (result != TransactionEditorResult.saved || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pemasukan tersimpan')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AtmosphereBackground(
        child: SafeArea(
          child: switch (_index) {
            0 => HomeScreen(
                onAddExpense: _openAddExpense,
                onAddIncome: _openAddIncome,
                onSeeAllBudgets: () => _goTo(1),
                onSeeAllTransactions: () => _goTo(2),
                onOpenProfile: () => _goTo(3),
                onRestartOnboarding: widget.onRestartOnboarding,
                userName: widget.displayName,
              ),
            1 => BudgetScreen(onOpenProfile: () => _goTo(3)),
            2 => const TransactionsScreen(),
            _ => ProfilScreen(
                appState: widget.appState,
                onRestartOnboarding: widget.onRestartOnboarding,
                userName: widget.displayName,
                userEmail: widget.userEmail,
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
