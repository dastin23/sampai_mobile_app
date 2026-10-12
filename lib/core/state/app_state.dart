import 'package:flutter/foundation.dart';

import '../models/plan.dart';

/// Penyimpanan data aplikasi: hanya rencana finansial (siklus gaji, tagihan,
/// tabungan) yang dipegang in-memory.
///
/// Anggaran dan transaksi **tidak** disimpan di sini — keduanya bersumber
/// dari Supabase lewat repository masing-masing (`transaction_providers`,
/// `budget_providers`).
class AppState extends ChangeNotifier {
  Plan? _plan;
  DateTime? _lastUpdatedAt;

  Plan? get plan => _plan;

  /// Waktu pembaruan data terakhir; null bila belum pernah ada data.
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  bool get hasPlan => _plan != null;

  /// Dipanggil setelah onboarding sukses: membuat salary cycle configuration.
  void applyPlan(Plan plan) {
    _plan = plan;
    _touch();
    notifyListeners();
  }

  /// Tandai data diperbarui (mis. setelah sinkronisasi terkonfirmasi).
  void touch() {
    _touch();
    notifyListeners();
  }

  /// Hapus seluruh data lokal (dipakai saat mulai ulang pengaturan).
  void clear() {
    _plan = null;
    _lastUpdatedAt = null;
    notifyListeners();
  }

  void _touch() => _lastUpdatedAt = DateTime.now();
}
