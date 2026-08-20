import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/platform_admin/platform_admin_providers.dart';
import '../../../core/theme/pspf_tokens.dart';

/// /platform-admin/login — DocSecore staff sign-in. Deliberately separate
/// from features/login/presentation/login_screen.dart: no MFA step, no
/// company/tenant concept, posts to platformAdminAuthControllerProvider
/// instead of authControllerProvider.
class PlatformAdminLoginScreen extends ConsumerStatefulWidget {
  const PlatformAdminLoginScreen({super.key});

  @override
  ConsumerState<PlatformAdminLoginScreen> createState() => _PlatformAdminLoginScreenState();
}

class _PlatformAdminLoginScreenState extends ConsumerState<PlatformAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(platformAdminAuthControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final authState = ref.watch(platformAdminAuthControllerProvider);
    final isSubmitting = authState.isLoading;
    final error = authState.hasError && authState.error is ApiException ? (authState.error as ApiException).message : null;

    return Scaffold(
      backgroundColor: tokens.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('DOCSECORE', style: TextStyle(fontSize: 12, letterSpacing: 2, color: tokens.ink2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Platform Administration', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Internal DocSecore staff only — separate from every client company\'s own sign-in.',
                    style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                  ),
                  const SizedBox(height: 24),
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: tokens.bad)),
                      child: Text(error, style: TextStyle(color: tokens.bad, fontSize: 12.5)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
