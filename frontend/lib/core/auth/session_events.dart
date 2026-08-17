import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Decouples the low-level auth interceptor (which has no business knowing
/// about the login state machine or go_router) from the rest of the app: it
/// just announces "the session is no longer valid" and whoever cares
/// (authControllerProvider, wired in auth_providers.dart) reacts.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onExpired => _controller.stream;

  void notifyExpired() => _controller.add(null);

  void dispose() => _controller.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
