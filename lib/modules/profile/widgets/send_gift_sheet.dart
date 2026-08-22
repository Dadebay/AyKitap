import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/account_service.dart';
import '../../../core/services/gift_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'gift_amount_section.dart';
import 'gift_hero.dart';
import 'gift_phone_section.dart';
import 'gift_sheet_frame.dart';
import 'gift_submit_button.dart';
import 'gift_success_dialog.dart';

part 'send_gift_sheet_actions.dart';

/// Profile's "send balance to a friend" flow: pick an amount, type the
/// recipient's phone, and once [GiftApiService.checkUserExists] confirms
/// they're a registered user, send it via [GiftApiService.sendToFriend].
/// Pops `true` after the success celebration so [ProfileScreen] can refresh.
class SendGiftSheet extends StatefulWidget {
  const SendGiftSheet({super.key});

  static const _presets = [10, 20, 50, 100];
  static const _digitsNeeded = 8; // XX XX XX XX, same as PhoneLoginScreen

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SendGiftSheet(),
    );
  }

  @override
  State<SendGiftSheet> createState() => _SendGiftSheetState();
}

class _SendGiftSheetState extends State<SendGiftSheet>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  late final AnimationController _borderController;

  GiftUserCheckStatus _userCheckStatus = GiftUserCheckStatus.idle;
  Timer? _userCheckDebounce;
  bool _sending = false;

  int? get _amount {
    final parsed = int.tryParse(_amountController.text.trim());
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  String get _phoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');
  bool get _phoneComplete => _phoneDigits.length == SendGiftSheet._digitsNeeded;
  String get _apiPhone => '+993$_phoneDigits';

  bool get _canSubmit =>
      !_sending &&
      _amount != null &&
      _userCheckStatus == GiftUserCheckStatus.found;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _amountFocusNode.addListener(_onAmountFocusChanged);
  }

  void _onAmountFocusChanged() => setState(() {});

  @override
  void dispose() {
    _userCheckDebounce?.cancel();
    _borderController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _amountFocusNode
      ..removeListener(_onAmountFocusChanged)
      ..dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // setState is @protected — the phone-check/submit methods in
  // send_gift_sheet_actions.dart live in an extension, not a subclass, so
  // they call this thin wrapper instead of setState directly.
  void _setState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) => GiftSheetFrame(
          progress: _borderController.value,
          child: child!,
        ),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .9),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const GiftHero(),
                const SizedBox(height: 24),
                GiftAmountSection(
                  presets: SendGiftSheet._presets,
                  selectedAmount: amount,
                  onPresetTap: (preset) =>
                      setState(() => _amountController.text = '$preset'),
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 22),
                GiftPhoneSection(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  onChanged: _onPhoneChanged,
                  showStatus: _phoneComplete,
                  status: _userCheckStatus,
                ),
                const SizedBox(height: 22),
                GiftSubmitButton(
                  canSubmit: _canSubmit,
                  sending: _sending,
                  amount: amount,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
