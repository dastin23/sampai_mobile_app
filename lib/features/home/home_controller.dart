import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import 'home_data.dart';
import 'home_demo_data.dart';

enum HomeStatus { loading, ready, error }

/// Mengelola pemuatan data Home dan pratinjau state (mode desain)
/// untuk pengujian acceptance criteria PRD 5.4.
class HomeController extends ChangeNotifier {
  HomeController(this._appState) {
    _appState.addListener(_onAppStateChanged);
  }

  final AppState _appState;

  HomeStatus _status = HomeStatus.loading;
  HomeData? _data;
  bool _firstUse = false;
  String? _previewNote;

  HomeStatus get status => _status;
  HomeData? get data => _data;
  bool get firstUse => _firstUse;

  /// Non-null bila layar menampilkan data contoh / state buatan.
  String? get previewNote => _previewNote;

  /// Muat data live; menampilkan skeleton selama proses.
  Future<void> load() async {
    _status = HomeStatus.loading;
    _previewNote = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    resolveLive();
  }

  void resolveLive() {
    final plan = _appState.plan;
    if (plan == null) {
      _firstUse = true;
      _data = null;
    } else {
      _firstUse = false;
      _data = HomeData.fromState(
        state: _appState,
        today: DateTime.now(),
        offline: false,
      );
    }
    _status = HomeStatus.ready;
    _previewNote = null;
    notifyListeners();
  }

  // ----------------------------------------------------- pratinjau state --

  void previewLoading() {
    _status = HomeStatus.loading;
    _previewNote = 'Pratinjau: memuat';
    notifyListeners();
  }

  void previewNormal() {
    _previewNote = null;
    resolveLive();
  }

  void previewWarning() {
    _data = demoWarningHome(today: DateTime.now(), offline: false);
    _firstUse = false;
    _status = HomeStatus.ready;
    _previewNote = 'Pratinjau: peringatan';
    notifyListeners();
  }

  void previewCritical() {
    _data = demoCriticalHome(today: DateTime.now());
    _firstUse = false;
    _status = HomeStatus.ready;
    _previewNote = 'Pratinjau: kritis';
    notifyListeners();
  }

  void previewOffline() {
    _data = demoWarningHome(today: DateTime.now(), offline: true);
    _firstUse = false;
    _status = HomeStatus.ready;
    _previewNote = 'Pratinjau: offline';
    notifyListeners();
  }

  void previewFirstUse() {
    _data = null;
    _firstUse = true;
    _status = HomeStatus.ready;
    _previewNote = 'Pratinjau: kosong';
    notifyListeners();
  }

  void previewError() {
    _status = HomeStatus.error;
    _previewNote = 'Pratinjau: error';
    notifyListeners();
  }

  void _onAppStateChanged() {
    if (_status == HomeStatus.ready && _previewNote == null) {
      resolveLive();
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }
}
