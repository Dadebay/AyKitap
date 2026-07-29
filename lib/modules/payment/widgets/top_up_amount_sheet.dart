import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// "Näçe manat dolduraly?" — the amount step of a bank-card balance top-up.
/// A subscription checkout skips this (the tariff sets the price); a top-up
/// has no inherent amount, so the user picks one. Presets cover the common
/// cases, the field handles everything else. Pops the chosen manat amount.
class TopUpAmountSheet extends StatefulWidget {
  const TopUpAmountSheet({super.key});

  static const _presets = [10, 20, 50, 100];

  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TopUpAmountSheet(),
    );
  }

  @override
  State<TopUpAmountSheet> createState() => _TopUpAmountSheetState();
}

class _TopUpAmountSheetState extends State<TopUpAmountSheet> {
  final _controller = TextEditingController();

  int? get _amount {
    final parsed = int.tryParse(_controller.text.trim());
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = _amount;
    if (amount == null) return;
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(PaymentStrings.topUpAmountTitle, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: TopUpAmountSheet._presets.map((preset) {
                final selected = amount == preset;
                return GestureDetector(
                  onTap: () => setState(() => _controller.text = '$preset'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.14) : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      PaymentStrings.manat(preset),
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.grey1,
                        fontSize: 13.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: PaymentStrings.topUpAmountHint,
                  hintStyle: TextStyle(color: AppColors.grey3, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: amount == null ? null : _submit,
                child: Text(PaymentStrings.topUpContinue, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
