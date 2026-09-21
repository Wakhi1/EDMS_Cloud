import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../api/api_providers.dart';
import '../api/endpoints.dart';
import '../env/env.dart';

/// Whether the app can actually reach [Env.apiBaseUrl] — checked with a
/// plain GET /health (no auth, no envelope) at startup, same pattern as
/// core/license/license_gate_provider.dart. This exists because a failed
/// login shows a generic "Request failed" for anything that isn't a real
/// {success:false, message} response from our own backend (a captive
/// portal, a WAF page, a wrong system clock breaking TLS, ...) — this
/// check runs first and reports the target URL plus the actual failure
/// reason, so that generic message isn't the only signal the user gets.
class ConnectivityState {
  const ConnectivityState({required this.checking, required this.reachable, this.error, this.debugInfo});

  final bool checking;
  final bool reachable;
  final String? error;

  /// TEMPORARY — see ApiException.debugInfo. Remove once root-caused.
  final String? debugInfo;
}

class ConnectivityGateController extends Notifier<ConnectivityState> {
  @override
  ConnectivityState build() {
    _check();
    return const ConnectivityState(checking: true, reachable: true);
  }

  Future<void> _check() async {
    state = const ConnectivityState(checking: true, reachable: true);
    try {
      await ref.read(apiClientProvider).get(Endpoints.health);
      state = const ConnectivityState(checking: false, reachable: true);
    } on ApiException catch (e) {
      state = ConnectivityState(checking: false, reachable: false, error: e.message, debugInfo: e.debugInfo);
    }
  }

  /// Re-runs the check — used by the login screen's retry banner.
  Future<void> recheck() => _check();
}

final connectivityGateControllerProvider =
    NotifierProvider<ConnectivityGateController, ConnectivityState>(ConnectivityGateController.new);
