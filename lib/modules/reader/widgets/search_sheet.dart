import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sakura_epub/sakura_epub.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_provider.dart';

/// TZ §12.3 — in-book search. A text field debounced onto
/// [ReaderProvider.search]; hits are grouped under the chapter they were found
/// in, with the query highlighted inside each excerpt. Tapping one jumps the
/// reader to that CFI.
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
                decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2)),
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

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ReaderStrings.searchTitle,
              style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (_hitCount > 0 && !_searching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ReaderStrings.searchResultCount(_hitCount),
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
              child: Icon(Icons.close, color: AppColors.grey2, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: AppColors.grey2, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _submit,
              style: TextStyle(color: AppColors.white, fontSize: 15),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: ReaderStrings.searchHint,
                hintStyle: TextStyle(color: AppColors.grey2, fontSize: 14),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _controller.clear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close_rounded, color: AppColors.grey2, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    final typed = _controller.text.trim();

    if (_searching && _rows.isEmpty) {
      return _hint(HugeIcons.strokeRoundedSearch01, ReaderStrings.searchSearching);
    }
    if (typed.isEmpty) {
      return _hint(HugeIcons.strokeRoundedSearch01, ReaderStrings.searchPrompt);
    }
    if (typed.length < _minQueryLength) {
      return _hint(HugeIcons.strokeRoundedSearch01, ReaderStrings.searchTooShort);
    }
    if (_rows.isEmpty) {
      // Nothing came back yet for a query long enough to search — either the
      // debounce hasn't fired or the search genuinely found nothing.
      if (_activeQuery.isEmpty) return _hint(HugeIcons.strokeRoundedSearch01, ReaderStrings.searchPrompt);
      return _hint(HugeIcons.strokeRoundedSearch01, ReaderStrings.searchNoResultsFor(_activeQuery));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _rows.length,
      itemBuilder: (_, i) {
        final row = _rows[i];
        if (row is _HeaderRow) return _chapterHeader(row);
        return _hitTile((row as _HitRow).result);
      },
    );
  }

  Widget _chapterHeader(_HeaderRow row) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: AppColors.primary, size: 14),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              row.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.grey1,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${row.count}',
            style: TextStyle(color: AppColors.grey3, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _hitTile(EpubSearchResult r) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.provider.epubController.display(cfi: r.cfi);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2.5,
                height: 34,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(children: _highlight(_clean(r.excerpt), _activeQuery)),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cappedNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        ReaderStrings.searchCapped(EpubController.searchResultLimit),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.grey2, fontSize: 11.5),
      ),
    );
  }

  /// [icon] is a `HugeIcons.*` constant — hugeicons models its glyphs as a JSON
  /// structure rather than an [IconData].
  Widget _hint(List<List<dynamic>> icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: AppColors.grey3, size: 34),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  /// epub.js builds excerpts by concatenating raw text nodes, so they arrive
  /// with the source file's newlines and indentation in them.
  String _clean(String excerpt) => excerpt.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Splits [text] around every case-insensitive occurrence of [query] so the
  /// match can be picked out from the surrounding sentence. Matching on the
  /// original string via RegExp (rather than indexing into a lowercased copy)
  /// keeps the offsets valid for characters whose lowercase form is a
  /// different length, such as Turkish İ.
  List<TextSpan> _highlight(String text, String query) {
    final base = TextStyle(color: AppColors.grey1, fontSize: 13.5, height: 1.45);
    if (query.isEmpty) return [TextSpan(text: text, style: base)];

    final hit = TextStyle(
      color: AppColors.primary,
      fontSize: 13.5,
      height: 1.45,
      fontWeight: FontWeight.w700,
    );

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final m in RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: base));
      }
      spans.add(TextSpan(text: text.substring(m.start, m.end), style: hit));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }
}

sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  final String title;
  final int count;
  const _HeaderRow(this.title, this.count);
}

class _HitRow extends _Row {
  final EpubSearchResult result;
  const _HitRow(this.result);
}
