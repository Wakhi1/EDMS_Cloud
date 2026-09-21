import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';

/// Whether the current user has a saved signature, and when it was last
/// updated — read by both the Settings "My Signature" tab and the
/// Approvals screen (to gate the Approve button on requires_signature
/// steps).
final mySignatureMetaProvider = FutureProvider.autoDispose<({bool hasSignature, String? updatedAt})>((ref) async {
  return ref.watch(signatureApiProvider).getMeta();
});

/// Signature image bytes fetched through the app's own Dio client — NOT
/// Image.network, which builds its own separate dart:io HttpClient that
/// doesn't carry this app's TLS trust-anchor fix
/// (core/api/dio_trust_anchor_io.dart) and caused a real production bug
/// (the login-screen company logo) earlier. Null if nothing saved.
final mySignatureImageBytesProvider = FutureProvider.autoDispose<Uint8List?>((ref) async {
  final bytes = await ref.watch(signatureApiProvider).getImageBytes();
  return bytes == null ? null : Uint8List.fromList(bytes);
});
