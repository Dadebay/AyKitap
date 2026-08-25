part of 'profile_screen.dart';

// Journey badge imports live at the top of the part file (not
// profile_screen.dart itself) since only the row builders below use them.

/// Row-builder methods for every [ProfileEntryCard] on the Profile tab, plus
/// the navigation/side-effect callbacks a couple of them own directly
/// (balance + gift, which don't belong in [_ProfileScreenSession]).
extension _ProfileScreenEntries on _ProfileScreenState {
  Future<void> _openBalance() async {
    await context.push(const BalanceScreen());
  }

  Future<void> _openSendGift() async {
    // The sheet awaits AccountService.refresh after a confirmed transfer.
    // This screen watches that service, so the profile balance card rebuilds
    // with the new value as soon as the success dialog is dismissed.
    await SendGiftSheet.show(context);
  }

  Widget _buildBalanceEntry(BuildContext context, int? balance) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedWallet01),
      title: ProfileStrings.balanceTitle,
      subtitle: balance != null ? PaymentStrings.manat(balance) : null,
      onTap: _openBalance,
    );
  }

  Widget _buildSendGiftButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedGift),
      title: GiftStrings.entryTitle,
      onTap: _openSendGift,
    );
  }

  // A live entitlement is account status rather than a routine settings row,
  // so it gets the dedicated premium card. Inactive users keep the compact
  // entry that leads to the same plan screen.
  Widget _buildSubscriptionEntry(
      BuildContext context, SubscriptionService subscription) {
    final active = subscription.isActive;
    final expiresAt = subscription.expiresAt;
    if (active && expiresAt != null) {
      return ActiveSubscriptionCard(
        expiresAt: expiresAt,
        onTap: () => context.push(const SubscriptionScreen()),
      );
    }
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedDiamond),
      title: ProfileStrings.subscription,
      subtitle: ProfileStrings.subscribeNow,
      onTap: () => context.push(const SubscriptionScreen()),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    // Watched here rather than off the singleton (with a bare
    // `context.watch<StreakService>()` up in build standing in for it): this
    // is the only thing on the screen that reads the streak, so keeping the
    // subscription next to the values it feeds means neither can be moved
    // or removed without the other.
    final streak = context.watch<StreakService>();
    return ProfileEntryCard(
      leading:
          const SizedBox(width: 40, height: 40, child: StreakFlame(size: 32)),
      title: ProfileStrings.streakDays(streak.currentStreak),
      subtitle: ProfileStrings.bestStreak(streak.bestStreak),
      extra: StreakWeekRow(weekRead: streak.weekRead, circleSize: 34),
      onTap: () => context.push(const StreakScreen()),
    );
  }

  Widget _buildSettingsEntry(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedSettings01),
      title: ProfileStrings.settingsEntryTitle,
      onTap: _openSettings,
    );
  }

  Widget _buildNotesButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedNote01),
      title: ProfileStrings.viewAllNotes,
      onTap: () => context.push(const NotesScreen()),
    );
  }

  Widget _buildBookRequestButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedBookOpen01),
      title: ProfileStrings.sendBookRequest,
      onTap: () => context.push(const BookSuggestionsScreen()),
    );
  }

  Widget _buildReportProblemButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedBug01),
      title: ProfileFeedbackStrings.reportProblemEntryTitle,
      onTap: () => ReportProblemSheet.show(context),
    );
  }
}
