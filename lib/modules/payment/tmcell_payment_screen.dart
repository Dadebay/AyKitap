import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/strings/payment_strings.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/tmcell_numbers_api_service.dart';
import '../../core/services/tmcell_payment_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import 'widgets/tmcell_payment_parts.dart';

/// "TMCELL arkaly töleg" — topping the balance up with a TMCELL balance
/// transfer, for a reader with no bank card.
///
/// Aýkitap never touches the money here. TMCELL moves it, between two of its
/// own numbers, when the reader sends an SMS; this screen only picks the
/// amount and hands the messaging app a ready-composed message. That is also
/// why nothing on this screen reports success: the app cannot know whether
/// the SMS was sent, and the balance arrives from the backend once the
/// transfer lands — see [TmcellPaymentConfig].
class TmcellPaymentScreen extends StatefulWidget {
  const TmcellPaymentScreen({super.key});

  @override
  State<TmcellPaymentScreen> createState() => _TmcellPaymentScreenState();
}

class _TmcellPaymentScreenState extends State<TmcellPaymentScreen> {
  int _amount = TmcellPaymentConfig.amounts.first;
  bool _agreed = false;
  String? _myPhone;

  /// The line the transfer goes to, from the admin panel's list. Null while
  /// it is still being fetched *and* after a fetch that found nothing — the
  /// two are told apart by [_loadingReceiver], because the screen has to say
  /// something different for each.
  String? _receiver;
  bool _loadingReceiver = true;

  @override
  void initState() {
    super.initState();
    _loadPhone();
    _loadReceiver();
  }

  Future<void> _loadPhone() async {
    final phone = await AuthSession.getPhone();
    if (!mounted) return;
    setState(() => _myPhone = phone);
  }

  /// A failed lookup falls back to the build-time number if this build was
  /// given one, and otherwise leaves [_receiver] null — the screen then says
  /// so and offers a retry instead of composing an SMS to nobody.
  Future<void> _loadReceiver({bool forceRefresh = false}) async {
    if (!_loadingReceiver) setState(() => _loadingReceiver = true);
    String? receiver;
    try {
      receiver =
          await TmcellNumbersApiService.getReceiver(forceRefresh: forceRefresh);
    } catch (_) {
      receiver = null;
    }
    receiver ??= TmcellPaymentConfig.fallbackReceiverPhone.isNotEmpty
        ? TmcellPaymentConfig.fallbackReceiverPhone
        : null;
    if (!mounted) return;
    setState(() {
      _receiver = receiver;
      _loadingReceiver = false;
    });
  }

  Future<void> _send() async {
    if (!_agreed) {
      context.showAppSnackBar(PaymentStrings.tmcellAgreeFirst, isError: true);
      return;
    }
    final receiver = _receiver;
    if (receiver == null) {
      context.showAppSnackBar(PaymentStrings.tmcellNumberUnavailable,
          isError: true);
      // The reader pressing the button is also the best moment to try the
      // lookup again — they are here, and the failure may have been a
      // moment's connectivity.
      _loadReceiver(forceRefresh: true);
      return;
    }
    final opened = await launchUrl(
      TmcellPaymentConfig.transferSms(receiver: receiver, amount: _amount),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      context.showAppSnackBar(PaymentStrings.tmcellSmsFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        title: Text(PaymentStrings.tmcellTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  if (_myPhone != null && _myPhone!.isNotEmpty) ...[
                    TmcellMyNumberCard(phone: _myPhone!),
                    const SizedBox(height: 10),
                  ],
                  TmcellReceiverCard(
                    phone: _receiver,
                    loading: _loadingReceiver,
                    onRetry: () => _loadReceiver(forceRefresh: true),
                  ),
                  const SizedBox(height: 18),
                  TmcellSectionLabel(PaymentStrings.tmcellAmountLabel),
                  const SizedBox(height: 10),
                  for (final amount in TmcellPaymentConfig.amounts) ...[
                    TmcellAmountRow(
                      amount: amount,
                      selected: _amount == amount,
                      onTap: () => setState(() => _amount = amount),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 10),
                  TmcellNoticeCard(
                    icon: HugeIcons.strokeRoundedMessage01,
                    text: PaymentStrings.tmcellHowItWorks(
                        TmcellPaymentConfig.smsShortCode),
                  ),
                  const SizedBox(height: 10),
                  TmcellNoticeCard(
                    icon: HugeIcons.strokeRoundedClock01,
                    text: PaymentStrings.tmcellArrivesLater,
                  ),
                  const SizedBox(height: 10),
                  TmcellNoticeCard(
                    icon: HugeIcons.strokeRoundedAlert02,
                    text: PaymentStrings.tmcellOnlyTmcell,
                    warning: true,
                  ),
                  const SizedBox(height: 16),
                  TmcellAgreementRow(
                    agreed: _agreed,
                    onChanged: (v) => setState(() => _agreed = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, 16 + MediaQuery.of(context).padding.bottom),
              child: TmcellSendButton(enabled: _agreed, onTap: _send),
            ),
          ],
        ),
      ),
    );
  }
}
