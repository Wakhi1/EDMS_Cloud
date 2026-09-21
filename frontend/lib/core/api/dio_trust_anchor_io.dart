import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// TEMPORARY — see ApiException.debugInfo. Remove once the server's
/// certificate is reissued from a CA with broader trust-store coverage
/// (tracking issue: edms.docsecuresd.com fails native TLS validation with
/// "CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate").
///
/// Root cause: on Android/iOS/desktop, dart:io's SecureSocket (what Dio
/// uses under the hood via IOHttpClientAdapter) validates certificates
/// against a CA bundle compiled into the Dart/Flutter engine itself — NOT
/// the OS's system trust store, and NOT Android's network_security_config
/// (that only governs the platform's own Java/Kotlin networking, e.g.
/// WebView/OkHttp — confirmed by testing: adding this same root there had
/// zero effect on Dio). The engine's bundled CA list doesn't yet include
/// "SSL.com TLS RSA Root CA 2022" (issued 2022 — relatively new), even on
/// devices whose OS/browser trusts it fine via their own, independently
/// updated root stores (which is why Chrome and curl were never affected).
///
/// This adds that one root as an extra trusted anchor ON TOP OF the
/// engine's built-in bundle (`withTrustedRoots: true` keeps the normal
/// list — this app still calls other hosts, e.g. Google/Microsoft sign-in,
/// and must keep trusting their certs too).
const _sslComRoot2022Pem = '''
-----BEGIN CERTIFICATE-----
MIIFiTCCA3GgAwIBAgIQb77arXO9CEDii02+1PdbkTANBgkqhkiG9w0BAQsFADBO
MQswCQYDVQQGEwJVUzEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMSUwIwYDVQQD
DBxTU0wuY29tIFRMUyBSU0EgUm9vdCBDQSAyMDIyMB4XDTIyMDgyNTE2MzQyMloX
DTQ2MDgxOTE2MzQyMVowTjELMAkGA1UEBhMCVVMxGDAWBgNVBAoMD1NTTCBDb3Jw
b3JhdGlvbjElMCMGA1UEAwwcU1NMLmNvbSBUTFMgUlNBIFJvb3QgQ0EgMjAyMjCC
AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANCkCXJPQIgSYT41I57u9nTP
L3tYPc48DRAokC+X94xI2KDYJbFMsBFMF3NQ0CJKY7uB0ylu1bUJPiYYf7ISf5OY
t6/wNr/y7hienDtSxUcZXXTzZGbVXcdotL8bHAajvI9AI7YexoS9UcQbOcGV0ins
S657Lb85/bRi3pZ7QcacoOAGcvvwB5cJOYF0r/c0WRFXCsJbwST0MXMwgsadugL3
PnxEX4MN8/HdIGkWCVDi1FW24IBydm5MR7d1VVm0U3TZlMZBrViKMWYPHqIbKUBO
L9975hYsLfy/7PO0+r4Y9ptJ1O4Fbtk085zx7AGL0SDGD6C1vBdOSHtRwvzpXGk3
R2azaPgVKPC506QVzFpPulJwoxJF3ca6TvvC0PeoUidtbnm1jPx7jMEWTO6Af77w
dr5BUxIzrlo4QqvXDz5BjXYHMtWrifZOZ9mxQnUjbvPNQrL8VfVThxc7wDNY8VLS
+YCk8OjwO4s4zKTGkH8PnP2L0aPP2oOnaclQNtVcBdIKQXTbYxE3waWglksejBYS
d66UNHsef8JmAOSqg+qKkK3ONkRN0VHpvB/zagX9wHQfJRlAUW7qglFA35u5CCoG
AtUjHBPW6dvbxrB6y3snm/vg1UYk7RBLY0ulBY+6uB0rpvqR4pJSvezrZ5dtmi2f
gTIFZzL7SAg/2SW4BCUvAgMBAAGjYzBhMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
BBgwFoAU+y437uOEeicuzRk1sTN8/9REQrkwHQYDVR0OBBYEFPsuN+7jhHonLs0Z
NbEzfP/UREK5MA4GA1UdDwEB/wQEAwIBhjANBgkqhkiG9w0BAQsFAAOCAgEAjYlt
hEUY8U+zoO9opMAdrDC8Z2awms22qyIZZtM7QbUQnRC6cm4pJCAcAZli05bg4vsM
QtfhWsSWTVTNj8pDU/0quOr4ZcoBwq1gaAafORpR2eCNJvkLTqVTJXojpBzOCBvf
R4iyrT7gJ4eLSYwfqUdYe5byiB0YrrPRpgqU+tvT5TgKa3kSM/tKWTcWQA673vWJ
DPFs0/dRa1419dvAJuoSc06pkZCmF8NsLzjUo3KUQyxi4U5cMj29TH0ZR6LDSeeW
P4+a0zvkEdiLA9z2tmBVGKaBUfPhqBVq6+AL8BQx1rmMRTqoENjwuSfr98t67wVy
lrXEj5ZzxOhWc5y8aVFjvO9nHEMaX3cZHxj4HCUp+UmZKbaSPaKDN7EgkaibMOlq
bLQjk2UEqxHzDh1TJElTHaE/nUiSEeJ9DU/1172iWD54nR4fK/4huxoTtrEoZP2w
AgDHbICivRZQIA9ygV/MlP+7mea6kMvq+cYMwq7FGc4zoWtcu358NFcXrfA/rs3q
r5nsLFR+jM4uElZI7xc7P0peYNLcdDa8pUNjyw9bowJWCZ4kLOGGgYz+qxcs+sji
Mho6/4UIyYOf8kpIEFR3N+2ivEC+5BB09+Rbu7nzifmPQdjH5FCQNYA+HLhNkNPU
98OwoX6EyneSMSy4kLGCenROmxMmtNVQZlR4rmA=
-----END CERTIFICATE-----
''';

/// Deliberately NOT a global HttpOverrides: overriding HttpOverrides.global
/// forces every HttpClient() call anywhere in the process — including ones
/// the Flutter engine creates internally during startup — to rebuild this
/// SecurityContext synchronously, which was slow/frequent enough to blow
/// past Android's ANR watchdog before the first frame ever rendered
/// (confirmed by bisection: removing just this one line fixed a startup
/// hang/crash reintroduced alongside it). Built once, here, and attached
/// only to this app's own Dio client below. Any other place that needs a
/// network image from this same host (e.g. the login screen's company
/// logo, core/widgets/company_logo_box.dart) fetches bytes through that
/// Dio client + Image.memory instead of Image.network's own separate
/// HttpClient, rather than reintroducing a second trust-anchor mechanism.
SecurityContext _buildTrustedContext() {
  return SecurityContext(withTrustedRoots: true)..setTrustedCertificatesBytes(utf8.encode(_sslComRoot2022Pem));
}

void applyTrustAnchors(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () => HttpClient(context: _buildTrustedContext()));
}
