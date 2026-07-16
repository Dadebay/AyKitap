import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../../core/data/mock/mock_data.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/widgets/app_back_button.dart';
import '../book_detail/book_detail_screen.dart';
import '../../core/localization/strings/author_strings.dart';

/// Ýazar Sahypasy — TZ section 11.
class AuthorScreen extends StatefulWidget {
  final Author author;
  const AuthorScreen({super.key, required this.author});

  @override
  State<AuthorScreen> createState() => _AuthorScreenState();
}

class _AuthorScreenState extends State<AuthorScreen> {
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final author = widget.author;
    final books = MockData.generateBooks(9, seed: author.id.hashCode.abs() % 100);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bg,
            pinned: true,
            leading: const AppBackButton(size: 20),
            title: Text(author.name, style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(color: author.color, shape: BoxShape.circle),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.white70, size: 40)),
                  ),
                  const SizedBox(height: 14),
                  Text(author.name, style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(AuthorStrings.booksCountLabel(books.length), style: TextStyle(color: AppColors.grey2, fontSize: 13)),
                  const SizedBox(height: 16),
                  Text(
                    author.bio,
                    textAlign: TextAlign.center,
                    maxLines: _bioExpanded ? null : 3,
                    overflow: _bioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.grey1, fontSize: 14, height: 1.55),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _bioExpanded = !_bioExpanded),
                    child: Text(
                      _bioExpanded ? AuthorStrings.showLess : AuthorStrings.readMore,
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AuthorStrings.allBooks, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final b = books[i];
                return GestureDetector(
                  onTap: () => context.push(BookDetailScreen(book: b)),
                  child: _AuthorBookTile(book: b),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        ),
      ),
    );
  }
}

class _AuthorBookTile extends StatelessWidget {
  final Book book;
  const _AuthorBookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(book.coverImage, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(book.publisher, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey3, size: 13),
                    const SizedBox(width: 4),
                    Text(AuthorStrings.pagesLabel(book.pages), style: TextStyle(color: AppColors.grey3, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 18),
        ],
      ),
    );
  }
}

/// "Main page deki yazarlarda hemmesini gor" — list of all authors.
class AllAuthorsScreen extends StatelessWidget {
  const AllAuthorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authors = MockData.authors;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        title: Text(AuthorStrings.authorsTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: authors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) {
          final a = authors[i];
          return GestureDetector(
            onTap: () => context.push(AuthorScreen(author: a)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: a.color, shape: BoxShape.circle),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.white70, size: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(a.name, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 18),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}
