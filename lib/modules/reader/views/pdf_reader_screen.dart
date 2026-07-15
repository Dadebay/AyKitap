import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// Minimal local-file PDF reader, opened from "Öz Kitaplarym" for imported
/// PDFs — the EPUB side already has the full-featured [ReaderScreen].
class PdfReaderScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfReaderScreen({super.key, required this.filePath, required this.title});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  int? _lastLoggedPage;
  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${_currentPage + 1}/$_totalPages', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_error == null)
            PDFView(
              filePath: widget.filePath,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) => setState(() {
                _totalPages = pages ?? 0;
                _isLoading = false;
              }),
              onPageChanged: (page, total) {
                final p = page ?? 0;
                if (_lastLoggedPage != null && p > _lastLoggedPage!) {
                  StreakService.instance.recordPageRead(count: (p - _lastLoggedPage!).clamp(1, 5));
                }
                _lastLoggedPage = p;
                setState(() => _currentPage = p);
              },
              onError: (error) => setState(() {
                _error = error.toString();
                _isLoading = false;
              }),
            ),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.white70)),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(ReaderStrings.pdfOpenError(_error!), style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}
