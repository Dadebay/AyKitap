import 'package:flutter/material.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_hero_tags.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/book_list_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/network_error_state.dart';
import '../../core/localization/strings/book_detail_strings.dart';
import '../home/widgets/catalog_book_card.dart';

/// Books returned by `GET /books/all?genre_id=:id`, reached from a genre
/// chip on [CatalogBookDetailScreen].
class CatalogGenreBooksScreen extends StatefulWidget {
  const CatalogGenreBooksScreen({super.key, required this.genreId, required this.genreName});

  final int genreId;
  final String genreName;

  @override
  State<CatalogGenreBooksScreen> createState() => _CatalogGenreBooksScreenState();
}

class _CatalogGenreBooksScreenState extends State<CatalogGenreBooksScreen> {
  List<LibraryBook>? _books;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final books = await BookListApiService.listBooks(genreIds: [widget.genreId]);
      if (!mounted) return;
      setState(() => _books = books);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(widget.genreName, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_books == null && _error == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) return NetworkErrorState(onRetry: _load);
    final books = _books!;
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(BookDetailStrings.noBooksInGenre, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: books.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 12, childAspectRatio: 0.50),
        itemBuilder: (context, index) => CatalogBookCard(book: books[index], heroTag: AppHeroTags.catalogBookCover(books[index].id), width: double.infinity, coverHeight: 170, margin: EdgeInsets.zero),
      ),
    );
  }
}
