import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/group_row.dart';
import '../../../core/models/user_row.dart';

class UsersFilters {
  const UsersFilters({this.role, this.departmentId, this.status});

  final String? role;
  final int? departmentId;
  final String? status; // 'active' | 'locked' | 'inactive'

  UsersFilters copyWith({String? Function()? role, int? Function()? departmentId, String? Function()? status}) {
    return UsersFilters(
      role: role != null ? role() : this.role,
      departmentId: departmentId != null ? departmentId() : this.departmentId,
      status: status != null ? status() : this.status,
    );
  }
}

final usersFiltersProvider = StateProvider.autoDispose<UsersFilters>((ref) => const UsersFilters());

final usersListProvider = FutureProvider.autoDispose<List<UserRow>>((ref) {
  final filters = ref.watch(usersFiltersProvider);
  return ref.watch(usersApiProvider).list(role: filters.role, departmentId: filters.departmentId, status: filters.status);
});

final groupsListProvider = FutureProvider.autoDispose<List<GroupRow>>((ref) {
  return ref.watch(usersApiProvider).listGroups();
});
