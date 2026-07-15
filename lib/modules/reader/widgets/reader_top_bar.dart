import 'package:flutter/material.dart';

class ReaderTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onChapters;

  const ReaderTopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onChapters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.list, color: Colors.white),
              onPressed: onChapters,
            ),
          ],
        ),
      ),
    );
  }
}
