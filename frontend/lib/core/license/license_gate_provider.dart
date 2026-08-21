import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../api/api_providers.dart';

/// The license-gate screen's state: has the initial GET /api/license/status
/// check finished, is this deployment currently licensed, and — while an
/// activation attempt is in flight or just failed — the usual
/// submitting/error pair every other step in this app's login-adjacent
/// flows uses (see core/auth/auth_state.dart).
class LicenseGateState {
  const LicenseGateState({required this.checking, required this.active, this.submitting = false, this.error});

  final bool checking;
  final bool active;
  final bool submitting;
  final String? error;

  LicenseGateState copyWith({bool? checking, bool? active, bool? submitting, String? error}) {
    return LicenseGateState(
      checking: checking ?? this.checking,
      active: active ?? this.active,
      submitting: submitting ?? this.submitting,
      error: error,
    );
  }
}

/// Hand-written [Notifier] (no code generation) — deliberately not an
/// [AsyncNotifier]: a failed status check must not replace the whole gate
/// with an error page, it should just fall back to *not blocking the app*
/// (see [_checkStatus]'s catch clause) while staying interactive.
class LicenseGateController extends Notifier<LicenseGateState> {
  @override
  LicenseGateState build() {
    _checkStatus();
    return const LicenseGateState(checking: true, active: false);
  }

  Future<void> _checkStatus() async {
    try {
      final status = await ref.read(licenseApiProvider).status();
      state = LicenseGateState(checking: false, active: status.active);
    } on ApiException {
      // The backend being unreachable (cold-start race, dev server still
      // booting) is not the same thing as "not licensed" — a real
      // license failure comes back as a normal {active:false} response,
      // not a thrown exception. Don't permanently trap the app behind
      // the activation screen just because this one check raced the
      // server coming up; go_router will simply re-evaluate on the next
      // navigation/refresh.
      state = const LicenseGateState(checking: false, active: true);
    }
  }

  /// Re-runs the check without resetting to the loading placeholder —
  /// used by the activation screen's "I've already activated it" retry.
  Future<void> recheck() => _checkStatus();

  Future<void> activate(String licenseKey) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      final status = await ref.read(licenseApiProvider).activate(licenseKey);
      state = LicenseGateState(
        checking: false,
        active: status.active,
        error: status.active ? null : 'Activation did not result in an active license.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(submitting: false, error: e.message);
    }
  }
}

final licenseGateControllerProvider = NotifierProvider<LicenseGateController, LicenseGateState>(LicenseGateController.new);
