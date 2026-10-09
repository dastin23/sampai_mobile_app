import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/models/plan.dart';

/// Seluruh data aplikasi satu user: rencana gaji, anggaran, dan transaksi.
///
/// Dipakai untuk menyalakan ulang Home setelah login (hydrate) dan untuk
/// menyimpan perubahan lewat [AppDataSync].
class AppDataSnapshot {
  const AppDataSnapshot({
    this.plan,
    this.budgets = const [],
    this.transactions = const [],
  });

  final Plan? plan;
  final List<BudgetCategory> budgets;
  final List<ExpenseTransaction> transactions;
}

/// Kontrak penyimpanan data Home ke backend agar dapat diuji tanpa Supabase.
abstract interface class AppDataRepository {
  Future<AppDataSnapshot> fetchAll();

  Future<void> saveAll(AppDataSnapshot snapshot);

  Future<void> deleteAll();
}

/// Implementasi Supabase (PostgREST) dengan Row Level Security.
///
/// [clientFactory] di-resolve malas (lazy) agar konstruksi aman di lingkungan
/// tanpa Supabase terinisialisasi (mis. test).
class SupabaseAppDataRepository implements AppDataRepository {
  SupabaseAppDataRepository({SupabaseClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? (() => supabase);

  final SupabaseClient Function() _clientFactory;

  SupabaseClient get _client => _clientFactory();

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Belum ada user login.');
    return user.id;
  }

  @override
  Future<AppDataSnapshot> fetchAll() async {
    final uid = _userId;

    final planRow = await _client
        .from('plans')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (planRow == null) return const AppDataSnapshot();

    final bills = await fetchBills(planRow['id'] as String);
    final budgets = await fetchBudgets(uid);
    final transactions = await fetchTransactions(uid);

    return AppDataSnapshot(
      plan: _planFromMap(planRow, bills),
      budgets: budgets,
      transactions: transactions,
    );
  }

  Future<List<FixedBill>> fetchBills(String planId) async {
    final rows = await _client
        .from('plan_bills')
        .select()
        .eq('plan_id', planId)
        .order('sort_order');
    return [
      for (final row in rows)
        FixedBill(
          id: row['id'] as String,
          name: (row['name'] as String?) ?? '',
          amount: (row['amount'] as num?)?.toInt() ?? 0,
          dueDay: (row['due_day'] as num?)?.toInt() ?? 1,
          active: (row['active'] as bool?) ?? true,
        ),
    ];
  }

  Future<List<BudgetCategory>> fetchBudgets(String uid) async {
    final rows = await _client
        .from('budgets')
        .select()
        .eq('user_id', uid);
    return [
      for (final row in rows)
        BudgetCategory(
          category: row['category'] as String,
          limit: (row['limit_amount'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  Future<List<ExpenseTransaction>> fetchTransactions(String uid) async {
    final rows = await _client
        .from('transactions')
        .select()
        .eq('user_id', uid);
    return [
      for (final row in rows)
        ExpenseTransaction(
          id: row['id'] as String,
          title: (row['title'] as String?) ?? '',
          category: (row['category'] as String?) ?? 'Lainnya',
          amount: (row['amount'] as num?)?.toInt() ?? 0,
          date: _parseDate(row['date']),
          countsTowardFlexibleBudget:
              (row['counts_toward_flexible'] as bool?) ?? true,
          isIncome: (row['is_income'] as bool?) ?? false,
        ),
    ];
  }

  @override
  Future<void> saveAll(AppDataSnapshot snapshot) async {
    final uid = _userId;
    final plan = snapshot.plan;

    if (plan != null) {
      final inserted = await _client.from('plans').upsert({
        'user_id': uid,
        'net_income': plan.netIncome,
        'payday_day': plan.paydayDay,
        'next_payday': _toDateString(plan.nextPayday),
        'savings_target': plan.savingsTarget,
        'safety_buffer': plan.safetyBuffer,
      }, onConflict: 'user_id').select('id').single();
      final planId = inserted['id'] as String;

      await _client.from('plan_bills').delete().eq('plan_id', planId);
      if (plan.bills.isNotEmpty) {
        await _client.from('plan_bills').insert([
          for (var i = 0; i < plan.bills.length; i++)
            {
              'plan_id': planId,
              'name': plan.bills[i].name,
              'amount': plan.bills[i].amount,
              'due_day': plan.bills[i].dueDay,
              'active': plan.bills[i].active,
              'sort_order': i,
            },
        ]);
      }
    }

    await _client.from('budgets').delete().eq('user_id', uid);
    if (snapshot.budgets.isNotEmpty) {
      await _client.from('budgets').insert([
        for (final b in snapshot.budgets)
          {'user_id': uid, 'category': b.category, 'limit_amount': b.limit},
      ]);
    }

    await _client.from('transactions').delete().eq('user_id', uid);
    if (snapshot.transactions.isNotEmpty) {
      await _client.from('transactions').insert([
        for (final t in snapshot.transactions)
          {
            'id': t.id,
            'user_id': uid,
            'title': t.title,
            'category': t.category,
            'amount': t.amount,
            'date': _toDateString(t.date),
            'counts_toward_flexible': t.countsTowardFlexibleBudget,
            'is_income': t.isIncome,
          },
      ]);
    }
  }

  @override
  Future<void> deleteAll() async {
    final uid = _userId;
    final planRow = await _client
        .from('plans')
        .select('id')
        .eq('user_id', uid)
        .maybeSingle();
    if (planRow != null) {
      await _client.from('plans').delete().eq('id', planRow['id'] as String);
    }
    await _client.from('budgets').delete().eq('user_id', uid);
    await _client.from('transactions').delete().eq('user_id', uid);
  }

  Plan _planFromMap(Map<String, dynamic> row, List<FixedBill> bills) => Plan(
    netIncome: (row['net_income'] as num?)?.toInt() ?? 0,
    paydayDay: (row['payday_day'] as num?)?.toInt() ?? 25,
    nextPayday: _parseNullableDate(row['next_payday']),
    bills: bills,
    savingsTarget: (row['savings_target'] as num?)?.toInt() ?? 0,
    safetyBuffer: (row['safety_buffer'] as num?)?.toInt() ?? 0,
  );

  static DateTime _parseDate(Object? value) {
    final parsed = DateTime.tryParse(value as String? ?? '');
    if (parsed == null) return DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _parseNullableDate(Object? value) {
    final text = value as String?;
    if (text == null || text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _toDateString(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}