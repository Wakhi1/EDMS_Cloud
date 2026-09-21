import 'package:dio/dio.dart';

/// Web build: dart:io / SecurityContext don't exist here, and the browser's
/// own (frequently-updated) root store already trusts edms.docsecuresd.com's
/// certificate — see dio_trust_anchor_io.dart's doc comment for why this is
/// needed on native platforms at all. No-op.
void applyTrustAnchors(Dio dio) {}
