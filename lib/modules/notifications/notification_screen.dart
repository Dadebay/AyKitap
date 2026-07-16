import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/notifications_strings.dart';

class _AppNotification {
  final List<List<dynamic>> icon;
  final String title;
  final String body;
  final String time;
  final bool unread;
  const _AppNotification({required this.icon, required this.title, required this.body, required this.time, this.unread = false});
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static List<_AppNotification> get _items => [
        _AppNotification(
          icon: HugeIcons.strokeRoundedBook02,
          title: NotificationsStrings.newBookTitle,
          body: NotificationsStrings.newBookBody,
          time: NotificationsStrings.newBookTime,
          unread: true,
        ),
        _AppNotification(
          icon: HugeIcons.strokeRoundedFire,
          title: NotificationsStrings.streakTitle,
          body: NotificationsStrings.streakBody,
          time: NotificationsStrings.streakTime,
          unread: true,
        ),
        _AppNotification(
          icon: HugeIcons.strokeRoundedDiscount01,
          title: NotificationsStrings.discountTitle,
          body: NotificationsStrings.discountBody,
          time: NotificationsStrings.discountTime,
        ),
        _AppNotification(
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
          title: NotificationsStrings.paymentTitle,
          body: NotificationsStrings.paymentBody,
          time: NotificationsStrings.paymentTime,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(NotificationsStrings.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: _items.isEmpty
          ? Center(child: Text(NotificationsStrings.empty, style: TextStyle(color: AppColors.grey2, fontSize: 15)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final n = _items[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: n.unread ? Border.all(color: AppColors.primary.withValues(alpha: 0.35)) : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Center(child: HugeIcon(icon: n.icon, color: AppColors.primary, size: 19)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(n.title, style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                ),
                                if (n.unread) Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.body, style: TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4)),
                            const SizedBox(height: 6),
                            Text(n.time, style: TextStyle(color: AppColors.grey3, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
