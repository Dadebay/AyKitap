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
import 'contact_row.dart';
import 'contact_us_header.dart';

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
    if (!ok && mounted) {
      context.showAppSnackBar(SettingsStrings.contactLinkOpenError,
          isError: true);
    }
  }

  /// A field the admin filled in, or null. Whitespace counts as empty, and
  /// so does a lone "@" — the Telegram box left with just its prefix.
  static String? _present(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '@') return null;
    return trimmed;
  }

  void _openTelegram(String tgName) {
    final username = tgName.trim().replaceFirst(RegExp(r'^@'), '');
    if (username.isEmpty) return;
    _open(Uri.parse('https://t.me/$username'));
  }

  void _openInstagram(String handle) {
    final username = handle.trim().replaceFirst(RegExp(r'^@'), '');
    if (username.isEmpty) return;
    _open(Uri.parse('https://instagram.com/$username'));
  }

  void _call(String phone) =>
      _open(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

  void _email(String email) => _open(Uri(scheme: 'mailto', path: email));

  void _openLink(String url) => _open(Uri.parse(url));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
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
              const ContactUsHeader(),
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
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey2, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _load,
                child: Text(SettingsStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }
    final contact = _contact;
    final rows = <Widget>[];
    // Blank-but-present values, not just missing ones. The admin panel saves
    // a field that was left alone as an empty (or whitespace) string rather
    // than omitting it, so `isNotEmpty` still passed and the sheet showed a
    // "Telegram" row with nothing under it and nothing to open — reported
    // with the panel's own Telegram field empty.
    final telegram = _present(contact?.tgName);
    final phone = _present(contact?.phone);
    final email = _present(contact?.email);
    final instagram = _present(contact?.instagram);
    final privacy = _present(contact?.privacyLink);
    final agreement = _present(contact?.userAgreementLink);

    if (telegram != null) {
      rows.add(ContactRow(
        icon: HugeIcons.strokeRoundedTelegram,
        label: SettingsStrings.contactTelegram,
        value: telegram,
        onTap: () => _openTelegram(telegram),
      ));
    }
    if (phone != null) {
      rows.add(ContactRow(
        icon: HugeIcons.strokeRoundedCall,
        label: SettingsStrings.contactPhone,
        value: phone,
        onTap: () => _call(phone),
      ));
    }
    if (email != null) {
      rows.add(ContactRow(
        icon: HugeIcons.strokeRoundedMail01,
        label: SettingsStrings.contactEmail,
        value: email,
        onTap: () => _email(email),
      ));
    }
    if (instagram != null) {
      rows.add(ContactRow(
        icon: HugeIcons.strokeRoundedInstagram,
        label: SettingsStrings.contactInstagram,
        value: instagram,
        onTap: () => _openInstagram(instagram),
      ));
    }
    if (privacy != null) {
      rows.add(ContactRow(
        icon: HugeIcons.strokeRoundedShield01,
        label: SettingsStrings.contactPrivacyPolicy,
        onTap: () => _openLink(privacy),
      ));
    }
    if (agreement != null) {
      rows.add(ContactRow(
        icon: HugeIcons.strokeRoundedContracts,
        label: SettingsStrings.contactUserAgreement,
        onTap: () => _openLink(agreement),
      ));
    }
    // Every channel blank: an empty sheet with just a heading reads as a
    // loading failure, so say plainly that there is nothing here.
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(SettingsStrings.contactNone,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 14)),
      );
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
