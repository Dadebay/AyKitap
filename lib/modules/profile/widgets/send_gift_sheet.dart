import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/account_service.dart';
import '../../../core/services/gift_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import 'gift_success_dialog.dart';

enum _UserCheckStatus { idle, checking, found, notFound, error }

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

  _UserCheckStatus _userCheckStatus = _UserCheckStatus.idle;
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
      _userCheckStatus == _UserCheckStatus.found;

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

  String _formatPhone(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      if (i % 2 == 1 && i != digits.length - 1) buf.write(' ');
    }
    return buf.toString();
  }

  void _onPhoneChanged(String value) {
    final allDigits = value.replaceAll(RegExp(r'\D'), '');
    final digits = allDigits.substring(
        0, allDigits.length.clamp(0, SendGiftSheet._digitsNeeded));
    final formatted = _formatPhone(digits);
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _userCheckDebounce?.cancel();
    if (digits.length < SendGiftSheet._digitsNeeded) {
      setState(() => _userCheckStatus = _UserCheckStatus.idle);
      return;
    }
    setState(() => _userCheckStatus = _UserCheckStatus.checking);
    _userCheckDebounce = Timer(const Duration(milliseconds: 500), _checkUser);
  }

  Future<void> _checkUser() async {
    final phoneAtRequest = _apiPhone;
    try {
      final exists =
          await GiftApiService.checkUserExists(phone: phoneAtRequest);
      // The phone field may have changed while this was in flight — a
      // stale response landing after a newer request must not overwrite it.
      if (!mounted || phoneAtRequest != _apiPhone) return;
      setState(() => _userCheckStatus =
          exists ? _UserCheckStatus.found : _UserCheckStatus.notFound);
    } on ApiException {
      if (!mounted || phoneAtRequest != _apiPhone) return;
      setState(() => _userCheckStatus = _UserCheckStatus.error);
    }
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (!_canSubmit || amount == null) return;
    setState(() => _sending = true);
    try {
      await GiftApiService.sendToFriend(
          phone: _apiPhone, amount: amount.toDouble());
      // The transfer has been confirmed by the backend. Refresh before the
      // success dialog so the profile balance behind it is already accurate
      // once the user taps "Done".
      await AccountService.instance.refresh();
      if (!mounted) return;
      await GiftSuccessDialog.show(context, amount: amount);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) => _GiftSheetFrame(
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
                _GiftHero(),
                const SizedBox(height: 24),
                _sectionLabel(GiftStrings.amountLabel, step: '1'),
                const SizedBox(height: 10),
                Row(
                  children: SendGiftSheet._presets.map((preset) {
                    final selected = amount == preset;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: preset == SendGiftSheet._presets.last ? 0 : 8,
                        ),
                        child: Semantics(
                          button: true,
                          selected: selected,
                          child: InkWell(
                            onTap: () => setState(
                              () => _amountController.text = '$preset',
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: .14)
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: selected ? 1.5 : 1,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: .15),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                '$preset',
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.grey1,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _amountFocusNode.hasFocus
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedWallet01,
                        color: _amountFocusNode.hasFocus
                            ? AppColors.primary
                            : AppColors.grey3,
                        size: 20,
                      ),
                      Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            hintText: GiftStrings.amountHint,
                            hintStyle: TextStyle(
                              color: AppColors.grey3,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Text(
                        'TMT',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _sectionLabel(GiftStrings.phoneLabel, step: '2'),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  hint: '__ __ __ __',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11)
                  ],
                  style: TextStyle(
                      color: AppColors.white, fontSize: 16, letterSpacing: 1),
                  onChanged: _onPhoneChanged,
                  prefix: Row(
                    children: [
                      Text('+993',
                          style: TextStyle(
                              color: AppColors.grey1,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 1,
                          height: 22,
                          color: AppColors.border),
                    ],
                  ),
                ),
                if (_phoneComplete) ...[
                  const SizedBox(height: 8),
                  _buildUserCheckStatus(),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _canSubmit
                          ? LinearGradient(
                              colors: [
                                AppColors.primary,
                                const Color(0xFFE85A73),
                              ],
                            )
                          : null,
                      color: _canSubmit
                          ? null
                          : AppColors.primary.withValues(alpha: .35),
                      boxShadow: _canSubmit
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .28),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _canSubmit ? _submit : null,
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedGift,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  amount != null
                                      ? GiftStrings.sendWithAmount(amount)
                                      : GiftStrings.send,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowRight01,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCheckStatus() {
    switch (_userCheckStatus) {
      case _UserCheckStatus.idle:
        return const SizedBox.shrink();
      case _UserCheckStatus.checking:
        return _statusRow(
          child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.grey2)),
          label: GiftStrings.checkingUser,
          color: AppColors.grey2,
        );
      case _UserCheckStatus.found:
        return _statusRow(
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
          label: GiftStrings.userFound,
          color: const Color(0xFF3FB950),
        );
      case _UserCheckStatus.notFound:
        return _statusRow(
          icon: HugeIcons.strokeRoundedCancelCircle,
          label: GiftStrings.userNotFound,
          color: const Color(0xFFE5484D),
        );
      case _UserCheckStatus.error:
        return _statusRow(
          icon: HugeIcons.strokeRoundedAlert02,
          label: GiftStrings.userCheckFailed,
          color: const Color(0xFFE5484D),
        );
    }
  }

  Widget _statusRow(
      {Widget? child,
      List<List<dynamic>>? icon,
      required String label,
      required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          child ?? HugeIcon(icon: icon!, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, {required String step}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey1,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A subtle, constantly moving light around the sheet — it gives the gift
/// flow a celebratory focus without using a heavyweight video or Lottie asset.
class _GiftSheetFrame extends StatelessWidget {
  const _GiftSheetFrame({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(28));
    final angle = progress * 6.28318530718;
    final colors = [
      AppColors.primary,
      const Color(0xFFF6C56D),
      const Color(0xFFB45CFF),
      const Color(0xFF4AB7FF),
      AppColors.primary,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient:
            SweepGradient(colors: colors, transform: GradientRotation(angle)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .24),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 1.5, left: 1.5, right: 1.5),
        child: DecoratedBox(
          decoration:
              BoxDecoration(color: AppColors.surface, borderRadius: radius),
          child: child,
        ),
      ),
    );
  }
}

class _GiftHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: .16),
            const Color(0xFF9B5CFF).withValues(alpha: .13),
            AppColors.card,
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF121426),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .28),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
                child:
                    Image.asset('assets/images/logo.webp', fit: BoxFit.cover)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedGift,
                  color: AppColors.primary,
                  size: 21),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  GiftStrings.sheetTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            GiftStrings.sheetSubtitle,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.grey2, fontSize: 12.5, height: 1.38),
          ),
        ],
      ),
    );
  }
}
