import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_record.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../capture/providers/capture_providers.dart';
import '../../repository/providers/repository_providers.dart';

const _kStatuses = <String>['draft', 'pending_approval', 'approved', 'rejected', 'declared_final', 'archived', 'disposed'];

class SearchFilters {
  const SearchFilters({this.folderId, this.status, this.documentTypeId, this.captureBatchId});

  final int? folderId;
  final String? status;
  final int? documentTypeId;
  final int? captureBatchId;

  bool get isEmpty => folderId == null && status == null && documentTypeId == null && captureBatchId == null;

  SearchFilters copyWith({
    int? Function()? folderId,
    String? Function()? status,
    int? Function()? documentTypeId,
    int? Function()? captureBatchId,
  }) {
    return SearchFilters(
      folderId: folderId != null ? folderId() : this.folderId,
      status: status != null ? status() : this.status,
      documentTypeId: documentTypeId != null ? documentTypeId() : this.documentTypeId,
      captureBatchId: captureBatchId != null ? captureBatchId() : this.captureBatchId,
    );
  }
}

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _searchFiltersProvider = StateProvider<SearchFilters>((ref) => const SearchFilters());

final _searchResultsProvider = FutureProvider<List<DocumentRecord>>((ref) {
  final q = ref.watch(_searchQueryProvider);
  final filters = ref.watch(_searchFiltersProvider);
  if (q.trim().isEmpty && filters.isEmpty) return Future.value(const []);
  return ref.watch(documentsApiProvider).search(
        q: q,
        folderId: filters.folderId,
        status: filters.status,
        documentTypeId: filters.documentTypeId,
        captureBatchId: filters.captureBatchId,
      );
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: _initialQuery());
  bool _showFilters = false;

  String _initialQuery() {
    final uri = GoRouterState.of(context).uri;
    return uri.queryParameters['q'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.text.isNotEmpty) {
        ref.read(_searchQueryProvider.notifier).state = _controller.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resultsAsync = ref.watch(_searchResultsProvider);
    final q = ref.watch(_searchQueryProvider);
    final filters = ref.watch(_searchFiltersProvider);
    final hasQuery = q.trim().isNotEmpty || !filters.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Records / Search & retrieval', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(isDense: true, hintText: 'Full text, member number, claim reference…'),
                        onSubmitted: (v) => ref.read(_searchQueryProvider.notifier).state = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => ref.read(_searchQueryProvider.notifier).state = _controller.text,
                      child: const Text('Search'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        _controller.clear();
                        ref.read(_searchQueryProvider.notifier).state = '';
                        ref.read(_searchFiltersProvider.notifier).state = const SearchFilters();
                      },
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      icon: Icon(_showFilters ? Icons.expand_less : Icons.tune, size: 16),
                      label: const Text('Filters'),
                    ),
                  ],
                ),
                if (_showFilters) ...[
                  const Divider(height: 20),
                  _FilterRow(filters: filters, onChanged: (f) => ref.read(_searchFiltersProvider.notifier).state = f),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!hasQuery)
            const Expanded(child: EmptyState(message: 'Enter a search term or choose a filter above to find records.'))
          else
            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(message: error is ApiException ? error.message : '$error'),
                data: (results) {
                  if (results.isEmpty) {
                    return const EmptyState(message: 'No records match. Try a member number, or clear the filters.');
                  }
                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = results[i];
                      return InkWell(
                        onTap: () => context.go(RoutePaths.viewerFor('${r.id}')),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.surf,
                            border: Border(left: BorderSide(color: tokens.acc, width: 3), top: BorderSide(color: tokens.line), right: BorderSide(color: tokens.line), bottom: BorderSide(color: tokens.line)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title, style: TextStyle(fontWeight: FontWeight.w600, color: tokens.accD)),
                                    const SizedBox(height: 2),
                                    Text('${r.recordNo} · ${r.department ?? '—'}', style: TextStyle(fontSize: 12, color: tokens.ink2)),
                                  ],
                                ),
                              ),
                              StatusChip.forDocumentStatus(r.status),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Folder/status/document-type filters were already supported server-side
/// (documents.routes.js's GET /) but never surfaced in the UI; capture-batch
/// is a new server-side param added alongside this panel.
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.filters, required this.onChanged});

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final typesAsync = ref.watch(documentTypesProvider);
    final batchesAsync = ref.watch(captureBatchListProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<int?>(
            initialValue: filters.folderId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Folder', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any folder')),
              for (final f in foldersAsync.valueOrNull ?? const []) DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => onChanged(filters.copyWith(folderId: () => v)),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: filters.status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any status')),
              for (final s in _kStatuses) DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))),
            ],
            onChanged: (v) => onChanged(filters.copyWith(status: () => v)),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<int?>(
            initialValue: filters.documentTypeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Document type', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any type')),
              for (final t in typesAsync.valueOrNull ?? const []) DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => onChanged(filters.copyWith(documentTypeId: () => v)),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            initialValue: filters.captureBatchId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Capture batch', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any batch')),
              for (final b in batchesAsync.valueOrNull ?? const [])
                DropdownMenuItem(value: b.id, child: Text('${b.batchNo} (${b.source.replaceAll('_', ' ')})', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => onChanged(filters.copyWith(captureBatchId: () => v)),
          ),
        ),
      ],
    );
  }
}
