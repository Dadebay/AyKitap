import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/profile_strings.dart';

/// "Kitap Haýyşy" — TZ 8.5.
class BookRequestSheet extends StatefulWidget {
  const BookRequestSheet({super.key});

  @override
  State<BookRequestSheet> createState() => _BookRequestSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const BookRequestSheet(),
    );
  }
}

class _BookRequestSheetState extends State<BookRequestSheet> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  String _language = ProfileStrings.languageTurkmen;

  static List<String> get _languages => [
        ProfileStrings.languageTurkmen,
        ProfileStrings.languageTurkish,
        ProfileStrings.languageRussian,
        ProfileStrings.languageEnglish,
        ProfileStrings.languageOther,
      ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ProfileStrings.requestSentMock)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Text(ProfileStrings.bookRequestTitle, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Text(ProfileStrings.bookRequestSubtitle, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
            const SizedBox(height: 20),
            _FieldLabel(ProfileStrings.bookTitleLabel),
            _TextField(controller: _titleController, hint: ProfileStrings.bookTitleHint),
            const SizedBox(height: 14),
            _FieldLabel(ProfileStrings.authorNameLabel),
            _TextField(controller: _authorController, hint: ProfileStrings.authorNameHint),
            const SizedBox(height: 14),
            _FieldLabel(ProfileStrings.languageLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((l) {
                final selected = l == _language;
                return GestureDetector(
                  onTap: () => setState(() => _language = l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(l, style: TextStyle(color: selected ? Colors.white : AppColors.grey1, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                onPressed: _submit,
                child: Text(ProfileStrings.send, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(color: AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w600));
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _TextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.white, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: AppColors.grey3), border: InputBorder.none),
      ),
    );
  }
}
