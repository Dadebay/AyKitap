import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The 56px card-background text field repeated across auth, profile, and
/// filter screens — border turns [AppColors.primary] on focus. Owns its own
/// [FocusNode] listener internally, so callers no longer need the
/// `onTap: () => setState(() {})` focus-repaint hack that was copy-pasted
/// at every call site.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.leadingIcon,
    this.style,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  }) : assert(prefix == null || leadingIcon == null,
            'use either prefix or leadingIcon, not both');

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// A static leading widget (e.g. the flag + "+993" prefix on the phone
  /// field) that doesn't react to focus.
  final Widget? prefix;

  /// A leading [HugeIcon] whose color follows focus state (e.g. the user
  /// icon on the name-entry field), mutually exclusive with [prefix].
  final List<List<dynamic>>? leadingIcon;

  final TextStyle? style;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    final field = Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.brLg,
        border:
            Border.all(color: hasFocus ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          if (widget.prefix != null) widget.prefix!,
          if (widget.leadingIcon != null) ...[
            HugeIcon(
                icon: widget.leadingIcon!,
                color: hasFocus ? AppColors.primary : AppColors.grey3,
                size: 20),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 1,
                height: 22,
                color: AppColors.border),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              style: widget.style ??
                  TextStyle(color: AppColors.white, fontSize: 16),
              decoration: InputDecoration(
                counterText: widget.maxLength != null ? '' : null,
                hintText: widget.hint,
                hintStyle: TextStyle(color: AppColors.grey3),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
        ],
      ),
    );
    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [Text(widget.label!, style: AppTextStyles.label), field],
    );
  }
}
