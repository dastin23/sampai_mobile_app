import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/app/state/app_providers.dart';
import 'package:sampai_app/core/models/plan.dart';
import 'package:sampai_app/features/auth/data/auth_repository.dart';
import 'package:sampai_app/features/auth/providers/auth_providers.dart';
import 'package:sampai_app/features/sync/data/app_data_repository.dart';
import 'package:sampai_app/features/sync/providers/app_data_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  bool authenticated = false;
  final StreamController<AuthState> _authController =
      StreamController<AuthState>.broadcast();

  @override
  Session? get currentSession => null;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Stream<AuthState> get authStateChanges => _authController.stream;

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    authenticated = true;
    return const AuthOutcome.success();
  }

  @override
  Future<AuthOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    authenticated = true;
    return const AuthOutcome.success();
  }

  @override
  Future<void> signOut() async {
    authenticated = false;
  }
}

class FakeAppDataRepository implements AppDataRepository {
  AppDataSnapshot snapshotToReturn = const AppDataSnapshot();
  bool failFetch = false;
  bool failSave = false;
  final List<AppDataSnapshot> saved = [];
  final List<String> log = [];

  @override
  Future<AppDataSnapshot> fetchAll() async {
    log.add('fetchAll');
    if (failFetch) throw StateError('Supabase belum diinisialisasi.');
    return snapshotToReturn;
  }

  @override
  Future<void> saveAll(AppDataSnapshot snapshot) async {
    log.add('saveAll');
    if (failSave) throw StateError('Supabase belum diinisialisasi.');
    saved.add(snapshot);
  }

  @override
  Future<void> deleteAll() async {
    log.add('deleteAll');
  }
}

Plan buildPlan() => Plan(
  netIncome: 5000000,
  paydayDay: 25,
  nextPayday: DateTime(2026, 10, 25),
  bills: [
    FixedBill(id: 'b1', name: 'Sewa', amount: 1200000, dueDay: 1),
    FixedBill(id: 'b2', name: 'Listrik', amount: 300000, dueDay: 15),
  ],
  savingsTarget: 500000,
  safetyBuffer: 500000,
);

void main() {
  late FakeAuthRepository auth;
  late FakeAppDataRepository repo;

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      appDataRepositoryProvider.overrideWithValue(repo),
    ],
  );

  setUp(() {
    auth = FakeAuthRepository();
    repo = FakeAppDataRepository();
  });

  group('AppDataSync (write-through)', () {
    testWidgets('rencana + transaksi tersimpan ke Supabase saat authed',
        (tester) async {
      auth.authenticated = true;
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);
      container.read(appDataSyncProvider);

      state.applyPlan(buildPlan());
      await tester.pump();

      state.addTransaction(
        ExpenseTransaction(
          id: 'tx-1',
          title: 'Makan siang',
          category: 'Makanan',
          amount: 25000,
          date: _today(),
        ),
      );
      await tester.pump();

      expect(repo.log, containsAll(['saveAll']));
      final latest = repo.saved.last;
      expect(latest.plan?.netIncome, 5000000);
      expect(latest.plan?.bills.length, 2);
      expect(latest.transactions.map((t) => t.id), contains('tx-1'));
    });

    testWidgets('tidak menyimpan saat belum login', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(appDataSyncProvider);
      container.read(appStateProvider).applyPlan(buildPlan());
      await tester.pump();

      expect(repo.log, isEmpty);
    });

    testWidgets('penyimpanan diduplikasi dihindari (dedupe)', (tester) async {
      auth.authenticated = true;
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);
      container.read(appDataSyncProvider);

      state.applyPlan(buildPlan());
      await tester.pump();
      final firstCount = repo.saved.length;
      expect(firstCount, 1, reason: 'rencana tersimpan satu kali');

      state.applyPlan(buildPlan());
      await tester.pump();
      expect(repo.saved.length, firstCount, reason: 'tidak diulang');

      state.addTransaction(
        ExpenseTransaction(
          id: 'tx-2',
          title: 'Bonus',
          category: 'Polosan',
          amount: 100000,
          isIncome: true,
          date: _today(),
        ),
      );
      await tester.pump();
      expect(repo.saved.length, firstCount + 1);
      expect(repo.saved.last.transactions.map((t) => t.id), contains('tx-2'));
    });

    testWidgets('kegagalan penyimpanan tidak dimuntahkan ke UI',
        (tester) async {
      auth.authenticated = true;
      repo.failSave = true;
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(appDataSyncProvider);
      container.read(appStateProvider).applyPlan(buildPlan());
      await tester.pump();

      repo.failSave = false;
      container
          .read(appStateProvider)
          .addTransaction(
            ExpenseTransaction(
              id: 'tx-retry',
              title: 'Makan',
              category: 'Makanan',
              amount: 10000,
              date: _today(),
            ),
          );
      await tester.pump();
      expect(repo.saved, isNotEmpty, reason: 'penyimpanan berikutnya normal');
      expect(repo.saved.last.transactions.map((t) => t.id), contains('tx-retry'));
    });
  });

  group('OnboardedNotifier.hydrate', () {
    testWidgets('memuat rencana, anggaran, dan transaksi dari Supabase',
        (tester) async {
      auth.authenticated = true;
      repo.snapshotToReturn = AppDataSnapshot(
        plan: buildPlan(),
        budgets: const [BudgetCategory(category: 'Makanan', limit: 800000)],
        transactions: [
          ExpenseTransaction(
            id: 'remote-1',
            title: 'Belanja',
            category: 'Makanan',
            amount: 50000,
            date: _today(),
          ),
        ],
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardedProvider.notifier);
      await notifier.hydrate();
      await tester.pump();

      final state = container.read(appStateProvider);
      expect(notifier.state, isTrue);
      expect(state.plan?.netIncome, 5000000);
      expect(state.budgets.single.category, 'Makanan');
      expect(state.transactions.single.id, 'remote-1');
    });

    testWidgets('tidak menindih rencana lokal yang sudah ada',
        (tester) async {
      auth.authenticated = true;
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);
      state.applyPlan(buildPlan());
      await tester.pump();

      await container.read(onboardedProvider.notifier).hydrate();
      expect(state.transactions, isEmpty, reason: 'data remote tidak dimuat');
    });

    testWidgets('gagal saat Supabase tidak tersedia tidak melempar',
        (tester) async {
      auth.authenticated = true;
      repo.failFetch = true;
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardedProvider.notifier);
      await notifier.hydrate();
      expect(notifier.state, isFalse);
      expect(container.read(appStateProvider).plan, isNull);
    });
  });

  group('OnboardedNotifier.reset', () {
    testWidgets('menghapus data remote dan mengosongkan state lokal',
        (tester) async {
      auth.authenticated = true;
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);
      state.applyPlan(buildPlan());
      await tester.pump();

      container.read(onboardedProvider.notifier).reset();
      await tester.pump();
      await tester.pump();

      expect(repo.log, contains('deleteAll'));
      expect(state.plan, isNull);
      expect(container.read(onboardedProvider), isFalse);
    });
  });
}

DateTime _today() => DateTime(2026, 10, 9);