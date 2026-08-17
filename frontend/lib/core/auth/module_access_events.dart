import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Broadcasts "the server just returned 403 for module access" so
/// core/router/app_router.dart can imperatively navigate to
/// /access-denied without api_client.dart needing to know about go_router.
/// Mirrors the pattern in session_events.dart.
class ModuleAccessEvents {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get onDenied => _controller.stream;

  void notifyDenied(String message) => _controller.add(message);

  void dispose() => _controller.close();
}

final moduleAccessEventsProvider = Provider<ModuleAccessEvents>((ref) {
  final events = ModuleAccessEvents();
  ref.onDispose(events.dispose);
  return events;
});

/// Holds the most recent denial message so AccessDeniedScreen can read it
/// without threading it through route parameters.
final lastDeniedMessageProvider = StateProvider<String?>((ref) => null);
