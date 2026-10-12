import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/app/state/app_providers.dart';
import 'package:sampai_app/core/models/plan.dart';
import 'package:sampai_app/features/auth/providers/auth_providers.dart';
import 'package:sampai_app/features/sync/data/app_data_repository.dart';
import 'package:sampai_app/features/sync/providers/app_data_providers.dart';

import 'helpers/fake_auth_repository.dart';

class FakeAppDataRepository implements AppDataRepository {
  Plan? planToReturn;
  bool failFetch = false;
  bool failSave = false;
  final List<Plan> saved = [];
  final List<String> log = [];

  @override
  Future<Plan?> fetchPlan() async {
    log.add('fetchPlan');
    if (failFetch) throw StateError('Supabase belum diinisialisasi.');
    return planToReturn;
  }

  @override
  Future<void> savePlan(Plan plan) async {
    log.add('savePlan');
    if (failSave) throw StateError('Supabase belum diinisialisasi.');
    saved.add(plan);
  }

  @override
  Future<void> deleteAll() async {
    log.add('deleteAll');
  }
}

Plan buildPlan({int netIncome = 5000000}) => Plan(
  netIncome: netIncome,
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
    testWidgets('rencana tersimpan ke Supabase saat authed', (tester) async {
      auth.authenticated = true;
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);
      container.read(appDataSyncProvider);

      state.applyPlan(buildPlan());
      await tester.pump();

      expect(repo.log, contains('savePlan'));
      final latest = repo.saved.last;
      expect(latest.netIncome, 5000000);
      expect(latest.bills.length, 2);
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

      state.applyPlan(buildPlan(netIncome: 6000000));
      await tester.pump();
      expect(repo.saved.length, firstCount + 1);
      expect(repo.saved.last.netIncome, 6000000);
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
      expect(repo.saved, isEmpty);

      repo.failSave = false;
      container.read(appStateProvider).applyPlan(buildPlan(netIncome: 7000000));
      await tester.pump();
      expect(repo.saved, isNotEmpty, reason: 'penyimpanan berikutnya normal');
      expect(repo.saved.last.netIncome, 7000000);
    });
  });

  group('OnboardedNotifier.hydrate', () {
    testWidgets('memuat rencana dari Supabase', (tester) async {
      auth.authenticated = true;
      repo.planToReturn = buildPlan();
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardedProvider.notifier);
      await notifier.hydrate();
      await tester.pump();

      final state = container.read(appStateProvider);
      expect(notifier.state, isTrue);
      expect(state.plan?.netIncome, 5000000);
    });

    testWidgets('tidak menindih rencana lokal yang sudah ada',
        (tester) async {
      auth.authenticated = true;
      repo.planToReturn = buildPlan(netIncome: 9000000);
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);
      state.applyPlan(buildPlan(netIncome: 5000000));
      await tester.pump();

      await container.read(onboardedProvider.notifier).hydrate();
      expect(state.plan?.netIncome, 5000000, reason: 'rencana lokal dipertahankan');
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
