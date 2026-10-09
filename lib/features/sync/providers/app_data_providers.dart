import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../app_data_sync.dart';
import '../data/app_data_repository.dart';

/// Repository data Home (rencana, anggaran, transaksi) berbasis Supabase.
final appDataRepositoryProvider = Provider<AppDataRepository>((ref) {
  return SupabaseAppDataRepository();
});

/// Write-through sinkronisasi [appStateProvider] ke Supabase.
/// Diinstansiasi oleh router agar aktif sepanjang sesi.
final appDataSyncProvider = Provider<AppDataSync>((ref) {
  final sync = AppDataSync(
    ref.read(appStateProvider),
    ref.read(appDataRepositoryProvider),
    ref.read(authRepositoryProvider),
  );
  ref.onDispose(sync.dispose);
  return sync;
});