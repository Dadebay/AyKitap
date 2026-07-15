import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:provider/provider.dart';
import '../provider/reader_provider.dart';
import '../../../core/localization/strings/reader_strings.dart';

class ChapterListSheet extends StatelessWidget {
  const ChapterListSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ReaderStrings.chaptersTitle,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Divider(color: Colors.white12, height: 24),
              Expanded(
                child: provider.chapters.isEmpty
                    ? Center(
                        child: Text(ReaderStrings.noChaptersFound, style: const TextStyle(color: Colors.white38)),
                      )
                    : ListView.builder(
                        itemCount: provider.chapters.length,
                        itemBuilder: (_, i) => _ChapterTile(
                          chapter: provider.chapters[i],
                          onTap: () {
                            provider.goToChapter(provider.chapters[i]);
                            Navigator.pop(context);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final EpubChapter chapter;
  final VoidCallback onTap;

  const _ChapterTile({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        chapter.title.isNotEmpty ? chapter.title : chapter.href,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      leading: const Icon(Icons.book_outlined, color: Colors.white38, size: 18),
      onTap: onTap,
    );
  }
}
