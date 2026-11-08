/// The `data` payload of `GET /contacts` — shown in [ContactUsSheet]
/// ("Biz bilen habarlaş", TZ 8.6).
class ContactInfo {
  final String? tgName;
  final String? startName;
  final String? phone;
  final String? email;
  final String? instagram;
  final String? privacyLink;
  final String? userAgreementLink;

  const ContactInfo({
    this.tgName,
    this.startName,
    this.phone,
    this.email,
    this.instagram,
    this.privacyLink,
    this.userAgreementLink,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        tgName: json['tg_name'] as String?,
        startName: json['start_name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        // The admin panel calls this field "Instagram"; the backend's key
        // for it isn't documented anywhere, so accept the spellings it
        // plausibly uses rather than silently showing nothing — which is
        // what happened while the app didn't read it at all.
        instagram: (json['instagram'] ??
            json['instagram_name'] ??
            json['insta_name'] ??
            json['insta']) as String?,
        privacyLink: json['privacy_link'] as String?,
        userAgreementLink: json['user_aggreement_link'] as String?,
      );
}
