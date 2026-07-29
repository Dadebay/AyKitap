import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/bank.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/payment_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// "Bank saýlaň" — shown before a bank-card payment so the user picks
/// which bank's online payment page to open. Fetches `GET /payments/banks`
/// itself so callers just await the picked [Bank].
class BankSelectSheet extends StatefulWidget {
  const BankSelectSheet({super.key});

  static Future<Bank?> show(BuildContext context) {
    return showModalBottomSheet<Bank>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const BankSelectSheet(),
    );
  }

  @override
  State<BankSelectSheet> createState() => _BankSelectSheetState();
}

class _BankSelectSheetState extends State<BankSelectSheet> {
  List<Bank>? _banks;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final banks = await PaymentApiService.getBanks();
      if (!mounted) return;
      setState(() {
        _banks = banks;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Text(PaymentStrings.selectBankTitle, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(PaymentStrings.banksLoadError, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(PaymentStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }
    final banks = _banks ?? const [];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: banks.map((bank) {
        final logo = bank.logoAsset;
        return InkWell(
          onTap: () => Navigator.pop(context, bank),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
                  child: logo != null
                      ? Image.asset(logo, fit: BoxFit.cover)
                      : Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBank, color: AppColors.grey2, size: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(bank.name, style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w600))),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
