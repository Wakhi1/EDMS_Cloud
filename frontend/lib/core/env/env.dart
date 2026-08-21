/// Compile-time environment configuration.
///
/// Override at run time with:
///   flutter run --dart-define=API_BASE_URL=https://edms.docsecuresd.com
class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://edms.docsecuresd.com',
  );
}
