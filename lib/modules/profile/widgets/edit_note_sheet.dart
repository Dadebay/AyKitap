import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/highlight_colors.dart';
import '../../../core/localization/strings/profile_strings.dart';

/// What [EditNoteSheet] returns when the reader saves — the note text plus the
/// ARGB highlight colour they picked.
typedef NoteDraft = ({String text, int colorValue});

/// Full page-style bottom sheet for adding/editing a note — a drag handle,
/// icon header, a colour picker, the text field, and a full-width primary
/// action. Reused by the reader (add a note on a selection, TZ 12.7) and the
/// profile's Notlar list (edit an existing note).
class EditNoteSheet extends StatefulWidget {
  final String initialText;

  /// Pre-selected highlight colour — the swatch the reader tapped, or the
  /// note's current colour when editing.
  final int initialColor;

  /// Header copy — defaults to the "edit" wording, but the reader reuses this
  /// sheet to *add* a note (TZ 12.7) with its own title/subtitle.
  final String? title;
  final String? subtitle;

  EditNoteSheet({
    super.key,
    required this.initialText,
    int? initialColor,
    this.title,
    this.subtitle,
  }) : initialColor = initialColor ?? HighlightColors.defaultColor.toARGB32();

  @override
  State<EditNoteSheet> createState() => _EditNoteSheetState();
}

class _EditNoteSheetState extends State<EditNoteSheet> {
  late final _controller = TextEditingController(text: widget.initialText);
  late int _color = widget.initialColor;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, (text: text, colorValue: _color));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Scrollable so the content never overflows when the keyboard is up on
        // short screens — it just scrolls instead of a RenderFlex overflow.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.grey3,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  HugeIcon(
                      icon: HugeIcons.strokeRoundedNoteAdd,
                      color: Color(_color),
                      size: 22),
                  const SizedBox(width: 10),
                  Text(widget.title ?? ProfileStrings.editNoteTitle,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              Text(widget.subtitle ?? ProfileStrings.editNoteSubtitle,
                  style: TextStyle(color: AppColors.grey2, fontSize: 13)),
              const SizedBox(height: 18),
              // ── Colour picker ─────────────────────────────────────────────
              Text(ProfileStrings.noteColorLabel,
                  style: TextStyle(
                      color: AppColors.grey2,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final c in HighlightColors.palette) ...[
                    _ColorDot(
                      color: c,
                      selected: c.toARGB32() == _color,
                      onTap: () => setState(() => _color = c.toARGB32()),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border(left: BorderSide(color: Color(_color), width: 3)),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 5,
                  minLines: 3,
                  style: TextStyle(
                      color: AppColors.white, fontSize: 14.5, height: 1.5),
                  decoration: InputDecoration(
                      hintText: ProfileStrings.noteTextHint,
                      hintStyle: TextStyle(color: AppColors.grey3),
                      border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  onPressed: _save,
                  child: Text(ProfileStrings.save,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(ProfileStrings.cancel,
                      style: TextStyle(color: AppColors.grey2, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable colour in the picker — grows and gains a ring when chosen.
class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.black87, size: 18)
            : null,
      ),
    );
  }
}
