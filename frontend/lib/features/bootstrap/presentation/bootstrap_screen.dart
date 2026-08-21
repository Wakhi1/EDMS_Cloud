import 'package:flutter/material.dart';

/// The app's actual initial route (see core/router/route_paths.dart and
/// app_router.dart's redirect) — never shows real content itself. Its only
/// job is to exist as somewhere neutral to sit while the license check
/// and the auth cold-start check are both still in flight, so neither
/// /login nor /dashboard nor anything else ever renders even briefly
/// before those checks have actually resolved.
class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
