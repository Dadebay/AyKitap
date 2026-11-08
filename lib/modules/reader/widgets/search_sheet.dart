import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sakura_epub/sakura_epub.dart';
import '../../../core/localization/strings/reader_search_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_provider.dart';

part 'search_sheet_header.dart';
part 'search_sheet_highlight.dart';
part 'search_sheet_results.dart';

/// TZ §12.3 — in-book search. A text field debounced onto
/// [ReaderProvider.search]; hits are grouped under the chapter they were found
/// in, with the query highlighted inside each excerpt. Tapping one jumps the
/// reader to that CFI.
///
/// Split across the `part` files above the same way [ReaderProvider] is:
/// header/search-field UI in search_sheet_header.dart, results list/row
/// building in search_sheet_results.dart, both as `extension`s on the private
/// State class so the split doesn't change behaviour.
class SearchSheet extends StatefulWidget {
  final ReaderProvider provider;
  const SearchSheet({super.key, required this.provider});

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  static const _minQueryLength = 2;

  final _controller = TextEditingController();
  Timer? _debounce;

  List<_Row> _rows = const [];
  int _hitCount = 0;
  bool _searching = false;

  /// The query the rows on screen belong to — drives highlighting and the
  /// "no results for X" message. Empty until a search has come back.
  String _activeQuery = '';

  /// Guards against a slow earlier search landing on top of a later one.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    // Driven from the controller rather than TextField.onChanged so that
    // clearing the field programmatically runs through the same path, and so
    // the clear button and body hints rebuild on every keystroke.
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final value = _controller.text.trim();
    _debounce?.cancel();
    if (value.length < _minQueryLength) {
      _requestId++;
      setState(() {
        _rows = const [];
        _hitCount = 0;
        _searching = false;
        _activeQuery = '';
      });
      return;
    }
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 450), () => _run(value));
  }

  void _submit(String value) {
    _debounce?.cancel();
    if (value.trim().length >= _minQueryLength) _run(value.trim());
  }

  Future<void> _run(String query) async {
    final id = ++_requestId;
    setState(() => _searching = true);

    List<EpubSearchResult> res;
    try {
      res = await widget.provider.search(query);
    } catch (_) {
      // Starting a search cancels the one in flight by erroring its completer,
      // so a superseded request lands here — the newer one owns the UI.
      if (!mounted || id != _requestId) return;
      setState(() {
        _rows = const [];
        _hitCount = 0;
        _searching = false;
        _activeQuery = query;
      });
      return;
    }

    if (!mounted || id != _requestId) return;
    setState(() {
      _rows = _group(res);
      _hitCount = res.length;
      _searching = false;
      _activeQuery = query;
    });
  }

  /// Flattens hits into chapter-header + hit rows, keeping the spine order the
  /// results already arrive in. One flat list keeps the ListView lazy instead
  /// of nesting a list per chapter.
  List<_Row> _group(List<EpubSearchResult> results) {
    // Keyed by href rather than by title: two chapters can carry the same
    // label, and it lets the title be resolved once per spine item below.
    final byHref = <String, List<EpubSearchResult>>{};
    for (final r in results) {
      byHref.putIfAbsent(r.href ?? '', () => []).add(r);
    }

    final rows = <_Row>[];
    byHref.forEach((href, hits) {
      // chapterTitleForHref walks the whole TOC tree, so resolve it per group
      // and not per hit — there can be 200 of them.
      final title = widget.provider.chapterTitleForHref(href) ?? '';
      // A hit whose href isn't in the TOC gets no header rather than a blank
      // one — better to show the excerpt bare than an empty label.
      if (title.isNotEmpty) rows.add(_HeaderRow(title, hits.length));
      rows.addAll(hits.map(_HitRow.new));
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grey3,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            _header(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _field(),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
            if (_hitCount >= EpubController.searchResultLimit) _cappedNote(),
          ],
        ),
      ),
    );
  }
}
