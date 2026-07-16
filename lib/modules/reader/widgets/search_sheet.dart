import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sakura_epub/sakura_epub.dart';
import '../provider/reader_provider.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// TZ §12.3 — in-book search. A text field debounced onto
/// [ReaderProvider.search]; tapping a hit jumps the reader to that CFI.
class SearchSheet extends StatefulWidget {
  final ReaderProvider provider;
  const SearchSheet({super.key, required this.provider});

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<EpubSearchResult> _results = const [];
  bool _searching = false;
  bool _hasQueried = false;

  static const _accent = Color(0xFFE86B2C);
  static const _panel = Color(0xFF1E1E2E);

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _hasQueried = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _run(value.trim()));
  }

  Future<void> _run(String query) async {
    setState(() => _searching = true);
    final res = await widget.provider.search(query);
    if (!mounted) return;
    setState(() {
      _results = res;
      _searching = false;
      _hasQueried = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            // Search field
            Container(
              height: 46,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      cursorColor: _accent,
                      decoration: InputDecoration(
                        hintText: ReaderStrings.searchHint,
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searching)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasQueried && _results.isEmpty) {
      return _centerHint(ReaderStrings.searchPrompt);
    }
    if (_hasQueried && _results.isEmpty && !_searching) {
      return _centerHint(ReaderStrings.searchNoResults);
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
      itemBuilder: (_, i) {
        final r = _results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          title: Text(
            r.excerpt.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          onTap: () {
            widget.provider.epubController.display(cfi: r.cfi);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _centerHint(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 14)),
    );
  }
}
