import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/models/own_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/own_books_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/own_book_spine_cover.dart';
import '../../reader/provider/reader_provider.dart';
import '../../reader/views/reader_view.dart';
import '../../reader/views/pdf_reader_screen.dart';
import 'shelf_grid.dart';

class OwnBooksTab extends StatefulWidget {
  const OwnBooksTab({super.key});

  @override
  State<OwnBooksTab> createState() => _OwnBooksTabState();
}

class _OwnBooksTabState extends State<OwnBooksTab> {
  final _store = OwnBooksStore.instance;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _pickFile() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub', 'pdf']);
      final picked = result?.files.single;
      final path = picked?.path;
      if (picked == null || path == null) return;
      await _store.addFromPickedFile(sourcePath: path, fileName: picked.name);
    } catch (e) {
      if (mounted) context.showAppSnackBar(LibraryStrings.fileAddError(e));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _openBook(OwnBook book) {
    AnalyticsService.instance.logBookOpened(id: book.id, format: book.format.name);
    if (book.format == OwnBookFormat.pdf) {
      context.push(PdfReaderScreen(filePath: book.filePath, title: book.title));
    } else {
      context.push(
        ChangeNotifierProvider(
          create: (_) => ReaderProvider(),
          child: ReaderScreen(bookPath: book.filePath, bookId: book.id.hashCode, bookTitle: book.title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<OwnBooksStore>().books;
    return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          children: [
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    if (_picking)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                      )
                    else
                      HugeIcon(icon: HugeIcons.strokeRoundedFolderAdd, color: AppColors.primary, size: 34),
                    const SizedBox(height: 10),
                    Text(LibraryStrings.addFileTitle, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(LibraryStrings.addFileSubtitle, style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (books.isNotEmpty) ...[
              Text(LibraryStrings.addedBooks, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ShelfGrid(
                itemCount: books.length,
                itemBuilder: (context, i) => OwnBookSpineCover(book: books[i], onTap: () => _openBook(books[i])),
              ),
              const SizedBox(height: 16),
            ],
            Text(LibraryStrings.localOnlyNotice, style: TextStyle(color: AppColors.grey3, fontSize: 12.5)),
          ],
        );
  }
}
