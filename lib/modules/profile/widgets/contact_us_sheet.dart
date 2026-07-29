import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/contact_info.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/contact_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/localization/strings/settings_strings.dart';

/// "Biz bilen habarlaş" — TZ 8.6. Fetches `GET /contacts` and shows each
/// channel as its own tappable row: Telegram and email open their app of
/// record, the phone number dials directly, and the two policy links open
/// in the browser.
class ContactUsSheet extends StatefulWidget {
  const ContactUsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ContactUsSheet(),
    );
  }

  @override
  State<ContactUsSheet> createState() => _ContactUsSheetState();
}

class _ContactUsSheetState extends State<ContactUsSheet> {
  ContactInfo? _contact;
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
      final contact = await ContactApiService.getContacts();
      if (!mounted) return;
      setState(() {
        _contact = contact;
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

  Future<void> _open(Uri uri) async {
    HapticFeedback.lightImpact();
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) context.showAppSnackBar(SettingsStrings.contactLinkOpenError, isError: true);
  }

  void _openTelegram(String tgName) {
    final username = tgName.trim().replaceFirst(RegExp(r'^@'), '');
    if (username.isEmpty) return;
    _open(Uri.parse('https://t.me/$username'));
  }

  void _call(String phone) => _open(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

  void _email(String email) => _open(Uri(scheme: 'mailto', path: email));

  void _openLink(String url) => _open(Uri.parse(url));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCustomerService01, color: AppColors.primary, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Text(SettingsStrings.contactUs, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 20),
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
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: Text(SettingsStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }
    final contact = _contact;
    final rows = <Widget>[];
    if (contact?.tgName != null && contact!.tgName!.isNotEmpty) {
      rows.add(_ContactRow(
        icon: HugeIcons.strokeRoundedTelegram,
        label: SettingsStrings.contactTelegram,
        value: contact.tgName!,
        onTap: () => _openTelegram(contact.tgName!),
      ));
    }
    if (contact?.phone != null && contact!.phone!.isNotEmpty) {
      rows.add(_ContactRow(
        icon: HugeIcons.strokeRoundedCall,
        label: SettingsStrings.contactPhone,
        value: contact.phone!,
        onTap: () => _call(contact.phone!),
      ));
    }
    if (contact?.email != null && contact!.email!.isNotEmpty) {
      rows.add(_ContactRow(
        icon: HugeIcons.strokeRoundedMail01,
        label: SettingsStrings.contactEmail,
        value: contact.email!,
        onTap: () => _email(contact.email!),
      ));
    }
    if (contact?.privacyLink != null && contact!.privacyLink!.isNotEmpty) {
      rows.add(_ContactRow(
        icon: HugeIcons.strokeRoundedShield01,
        label: SettingsStrings.contactPrivacyPolicy,
        onTap: () => _openLink(contact.privacyLink!),
      ));
    }
    if (contact?.userAgreementLink != null && contact!.userAgreementLink!.isNotEmpty) {
      rows.add(_ContactRow(
        icon: HugeIcons.strokeRoundedContracts,
        label: SettingsStrings.contactUserAgreement,
        onTap: () => _openLink(contact.userAgreementLink!),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1) Divider(color: AppColors.border, height: 1),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _ContactRow({required this.icon, required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(child: HugeIcon(icon: icon, color: AppColors.primary, size: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: AppColors.grey2, fontSize: 12, fontWeight: FontWeight.w600)),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 16),
          ],
        ),
      ),
    );
  }
}
