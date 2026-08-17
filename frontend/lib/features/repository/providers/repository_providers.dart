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

final repositoryDocumentsProvider = FutureProvider.autoDispose<List<DocumentRecord>>((ref) {
  final filters = ref.watch(repositoryFiltersProvider);
  return ref.watch(documentsApiProvider).search(q: filters.q, folderId: filters.folderId, status: filters.status);
});

final selectedDocumentProvider = StateProvider<DocumentRecord?>((ref) => null);
