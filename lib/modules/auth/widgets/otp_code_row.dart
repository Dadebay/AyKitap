import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// The row of single-digit boxes on [OtpVerifyScreen] — each one a plain
/// [TextField] whose border tints once filled, auto-advancing focus as the
/// user types.
class OtpCodeRow extends StatelessWidget {
  const OtpCodeRow({
    super.key,
    required this.length,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final int length;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (i) => _DigitBox(
            controller: controllers[i],
            focusNode: focusNodes[i],
            onChanged: (v) => onChanged(i, v),
          )),
    );
  }
}

class _DigitBox extends StatefulWidget {
  const _DigitBox({required this.controller, required this.focusNode, required this.onChanged});

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;
    return SizedBox(
      width: 68,
      height: 64,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: filled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: filled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
