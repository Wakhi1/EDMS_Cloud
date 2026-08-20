// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserHash() => r'1bcdd82003222b6edcf9316b6a49974804198ec3';

/// Derived convenience accessor — null until authenticated.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<AppUser?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<AppUser?>;
String _$authControllerHash() => r'10f5b8503887cc68e378a6a3a2b7bc46882ed551';

/// See also [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, LoginState>.internal(
      AuthController.new,
      name: r'authControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthController = AutoDisposeAsyncNotifier<LoginState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
