/// Compile-time environment configuration.
///
/// Override at run time with:
///   flutter run --dart-define=API_BASE_URL=http://localhost:4000
class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
}
