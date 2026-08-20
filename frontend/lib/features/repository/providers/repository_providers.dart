import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/document_record.dart';
import '../../../core/models/document_type_row.dart';
import '../../../core/models/folder_row.dart';

final foldersProvider = FutureProvider.autoDispose<List<FolderRow>>((ref) {
  return ref.watch(foldersApiProvider).list();
});

/// Shared lookup, also used by Smart Upload's type dropdown/suggestions.
final documentTypesProvider = FutureProvider.autoDispose<List<DocumentTypeRow>>((ref) {
  return ref.watch(documentTypesApiProvider).list();
});

class RepositoryFilters {
  const RepositoryFilters({this.folderId, this.q = '', this.status});

  final int? folderId;
  final String q;
  final String? status;

  RepositoryFilters copyWith({int? Function()? folderId, String? q, String? Function()? status}) {
    return RepositoryFilters(
      folderId: folderId != null ? folderId() : this.folderId,
      q: q ?? this.q,
      status: status != null ? status() : this.status,
    );
  }
}

final repositoryFiltersProvider = StateProvider<RepositoryFilters>((ref) => const RepositoryFilters());

/// Recycle bin is a separate on/off switch from [RepositoryFilters.status]
/// rather than reusing that field directly — archived records should never
/// silently show up just because a status filter happens to get set to
/// "archived" some other way, and turning the bin off should restore
/// whatever status filter (if any) was already selected.
final repositoryRecycleBinProvider = StateProvider<bool>((ref) => false);

final repositoryDocumentsProvider = FutureProvider.autoDispose<List<DocumentRecord>>((ref) {
  final filters = ref.watch(repositoryFiltersProvider);
  final recycleBin = ref.watch(repositoryRecycleBinProvider);
  return ref.watch(documentsApiProvider).search(
        q: filters.q,
        folderId: filters.folderId,
        status: recycleBin ? 'archived' : filters.status,
      );
});

final selectedDocumentProvider = StateProvider<DocumentRecord?>((ref) => null);

enum RepositoryViewMode { list, grid }

final repositoryViewModeProvider = StateProvider<RepositoryViewMode>((ref) => RepositoryViewMode.list);

/// Manual override for the properties panel, independent of the width
/// breakpoint that decides whether it's offered at all.
final repositoryDetailsCollapsedProvider = StateProvider<bool>((ref) => false);
