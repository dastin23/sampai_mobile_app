import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Menandai bahwa sesi saat ini berasal dari link reset kata sandi
/// (`passwordRecovery`). Selama `true`, router mengunci pengguna di
/// `/set-new-password` hingga kata sandi baru berhasil disimpan.
class PendingPasswordReset extends Notifier<bool> {
  @override
  bool build() => false;

  void markFromRecovery() => state = true;

  void clear() => state = false;
}

final pendingPasswordResetProvider =
    NotifierProvider<PendingPasswordReset, bool>(PendingPasswordReset.new);