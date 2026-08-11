import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_prefs.dart';
import '../../core/localization/strings/onboarding_strings.dart';
import 'language_select_screen.dart';
import 'widgets/onboard_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _current = 0;

  // A getter (not `static final`) so the copy recomputes from
  // [OnboardingStrings] every time the active language changes, instead of
  // being cached in the currently-active language forever.
  static List<OnboardPageData> get _pages => [
        OnboardPageData(
          gradient: const [Color(0xFF1A1035), Color(0xFF13131A)],
          accentColor: AppColors.primary,
          image: 'assets/images/onboarding/onboarding_1.webp',
          title: OnboardingStrings.page1Title,
          subtitle: OnboardingStrings.page1Subtitle,
          badge: OnboardingStrings.page1Badge,
          badgeLabel: OnboardingStrings.page1BadgeLabel,
        ),
        OnboardPageData(
          gradient: const [Color(0xFF0D2035), Color(0xFF13131A)],
          accentColor: const Color(0xFF3B82F6),
          image: 'assets/images/onboarding/onboarding_2.webp',
          title: OnboardingStrings.page2Title,
          subtitle: OnboardingStrings.page2Subtitle,
          badge: OnboardingStrings.page2Badge,
          badgeLabel: OnboardingStrings.page2BadgeLabel,
        ),
        OnboardPageData(
          gradient: const [Color(0xFF1A2810), Color(0xFF13131A)],
          accentColor: const Color(0xFF22C55E),
          image: 'assets/images/onboarding/onboarding_3.webp',
          title: OnboardingStrings.page3Title,
          subtitle: OnboardingStrings.page3Subtitle,
          badge: OnboardingStrings.page3Badge,
          badgeLabel: OnboardingStrings.page3BadgeLabel,
        ),
      ];

  void _next() {
    if (_current < _pages.length - 1) {
      setState(() => _current++);
    } else {
      _goHome();
    }
  }

  void _previous() {
    if (_current > 0) setState(() => _current--);
  }

  void _goHome() {
    // Remember that the intro has been completed so it never shows again.
    AppPrefs.setOnboardingSeen();
    // First-time entry only — the one-time language picker sits between
    // onboarding and the app itself, whether the user skipped or finished.
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LanguageSelectScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final size = MediaQuery.of(context).size;
    final page = _pages[_current];
    // Height of the bottom controls bar (top pad + 56px button + bottom pad),
    // used to keep page text from overlapping it.
    final bottomControlsHeight = 20 + 56 + 24 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Pages ─────────────────────────────────────────────────────
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -200) {
                _next();
              } else if (velocity > 200) {
                _previous();
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: OnboardPage(
                key: ValueKey(_current),
                data: page,
                textBottom: bottomControlsHeight + 16,
              ),
            ),
          ),

          // ── Skip ──────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: AnimatedOpacity(
              opacity: _current < _pages.length - 1 ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _goHome,
                child: Text(OnboardingStrings.skip, style: TextStyle(color: AppColors.grey2, fontSize: 15)),
              ),
            ),
          ),

          // ── Bottom controls ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).padding.bottom + 24),
              child: Row(
                children: [
                  AnimatedSmoothIndicator(
                    activeIndex: _current,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                      activeDotColor: page.accentColor,
                      dotColor: AppColors.grey3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _current == _pages.length - 1 ? size.width * 0.44 : 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: page.accentColor,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: page.accentColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: _current == _pages.length - 1
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(OnboardingStrings.start, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
