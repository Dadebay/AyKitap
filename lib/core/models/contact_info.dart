/// The `data` payload of `GET /contacts` — shown in [ContactUsSheet]
/// ("Biz bilen habarlaş", TZ 8.6).
class ContactInfo {
  final String? tgName;
  final String? startName;
  final String? phone;
  final String? email;
  final String? privacyLink;
  final String? userAgreementLink;

  const ContactInfo({
    this.tgName,
    this.startName,
    this.phone,
    this.email,
    this.privacyLink,
    this.userAgreementLink,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        tgName: json['tg_name'] as String?,
        startName: json['start_name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        privacyLink: json['privacy_link'] as String?,
        userAgreementLink: json['user_aggreement_link'] as String?,
      );
}
