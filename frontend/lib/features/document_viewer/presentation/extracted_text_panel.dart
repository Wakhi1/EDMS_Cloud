import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../providers/viewer_providers.dart';

/// Search-and-highlight over the document's OCR/extracted text — the
/// "Ctrl+F within this record" feature. Text is fetched lazily (only once
/// expanded, since ocr_text can be large) and matches are found via plain
/// case-insensitive substring search — no page rendering or word-position
/// data involved, per the approved Phase 2 scope (highlight in a text
/// panel, not overlaid on a rendered page image).
class ExtractedTextPanel extends ConsumerStatefulWidget {
  const ExtractedTextPanel({super.key, required this.documentId});

  final int documentId;

  @override
  ConsumerState<ExtractedTextPanel> createState() => _ExtractedTextPanelState();
}

class _ExtractedTextPanelState extends ConsumerState<ExtractedTextPanel> {
  bool _expanded = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int _currentMatch = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _matchStarts(String text) {
    if (_query.isEmpty) return const [];
    final lowerText = text.toLowerCase();
    final lowerQuery = _query.toLowerCase();
    final starts = <int>[];
    var from = 0;
    while (true) {
      final i = lowerText.indexOf(lowerQuery, from);
      if (i < 0) break;
      starts.add(i);
      from = i + lowerQuery.length;
    }
    return starts;
  }

  void _jumpTo(int index, int totalMatches, String fullText) {
    if (totalMatches == 0) return;
    setState(() => _currentMatch = index % totalMatches);
    // Approximate scroll position by character-offset ratio — there's no
    // page/word-position data to scroll to precisely, and this is a plain
    // text panel, not a rendered page (see class doc comment).
    final starts = _matchStarts(fullText);
    if (starts.isEmpty || !_scrollController.hasClients) return;
    final ratio = starts[_currentMatch] / fullText.length;
    final target = (_scrollController.position.maxScrollExtent * ratio).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _expanded = true),
          icon: const Icon(Icons.text_snippet_outlined, size: 16),
          label: const Text('Show extracted text'),
        ),
      );
    }

    final ocrAsync = ref.watch(documentOcrTextProvider(widget.documentId));

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.line))),
            child: Row(
              children: [
                Text('EXTRACTED TEXT', style: textTheme.labelSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Hide',
                  onPressed: () => setState(() => _expanded = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ocrAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error is ApiException ? error.message : '$error',
                    style: TextStyle(color: tokens.ink2),
                  ),
                ),
              ),
              data: (text) {
                if (text == null || text.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No extracted text is available for this record (OCR/text extraction '
                        'found nothing, or this version predates the extraction pipeline).',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tokens.ink2),
                      ),
                    ),
                  );
                }
                final matches = _matchStarts(text);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(isDense: true, hintText: 'Search within this record…'),
                              onChanged: (v) => setState(() {
                                _query = v;
                                _currentMatch = 0;
                              }),
                              onSubmitted: (_) => _jumpTo(_currentMatch + 1, matches.length, text),
                            ),
                          ),
                          if (_query.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              matches.isEmpty ? 'No matches' : '${_currentMatch + 1} of ${matches.length}',
                              style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                              tooltip: 'Previous match',
                              onPressed: matches.isEmpty ? null : () => _jumpTo(_currentMatch - 1, matches.length, text),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                              tooltip: 'Next match',
                              onPressed: matches.isEmpty ? null : () => _jumpTo(_currentMatch + 1, matches.length, text),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(14),
                          child: SelectableText.rich(
                            _highlightedSpan(text, matches, tokens),
                            style: const TextStyle(fontSize: 12.5, height: 1.6, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _highlightedSpan(String text, List<int> matches, PspfTokens tokens) {
    if (matches.isEmpty || _query.isEmpty) {
      return TextSpan(text: text);
    }
    final spans = <TextSpan>[];
    var cursor = 0;
    for (var i = 0; i < matches.length; i++) {
      final start = matches[i];
      final end = start + _query.length;
      if (start > cursor) spans.add(TextSpan(text: text.substring(cursor, start)));
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: TextStyle(
            backgroundColor: i == _currentMatch ? tokens.acc2 : tokens.acc2.withValues(alpha: 0.35),
            color: i == _currentMatch ? Colors.white : null,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(children: spans);
  }
}
