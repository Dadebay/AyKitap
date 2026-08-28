import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/layout/phone_safe_canvas.dart';
import '../../core/services/deep_link_service.dart';
import '../../core/services/incoming_file_service.dart';
import '../../core/services/notification_permission_flow.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/localization/app_locale.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../reader/views/reader_tab_screen.dart';
import 'widgets/wheel_nav_bar.dart';

class MainNavScreen extends StatefulWidget {
  /// The tab to display when entering the app shell. The default remains
  /// Home, while the offline screen can take the reader straight to Library.
  final int initialIndex;
  final int libraryInitialTabIndex;

  const MainNavScreen({
    super.key,
    this.initialIndex = 2,
    this.libraryInitialTabIndex = 0,
  })  : assert(initialIndex >= 0 && initialIndex < 5),
        assert(libraryInitialTabIndex >= 0 && libraryInitialTabIndex < 6);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  // Tab order: Profile, Kitaplyk, Ana sayfa (centre — opens by default),
  // Çytalka (reader), Poisk. Must stay in lockstep with _icons in
  // WheelNavBar, which draws the wheel in this same order.
  static const _readerTabIndex = 3;
  late int _selectedIndex;
  late int _prevIndex;
  // +1 → the new page slides in from the right (wheel spins forward);
  // -1 → in from the left. Kept in sync with the wheel's rotation direction.
  int _slideDir = 1;

  // Page widgets are cached (not rebuilt from a getter each frame): during
  // the slide the AnimatedBuilder ticks ~60fps, and re-creating heavy pages
  // like HomeScreen every tick would tank the framerate and make the
  // transition look like a freeze. Passing the *same* instances lets Flutter
  // skip rebuilding them, so only the cheap translation animates. Rebuilt on
  // theme/language change so AppColors and every screen's strings are re-read
  // — these tabs are never re-pushed via Navigator, so nothing else forces
  // them to notice AppLocale changing.
  late List<Widget> _pages = _buildPages();

  // Each tab is wrapped in PhoneSafeCanvas rather than the Stack as a whole:
  // FractionalTranslation (in _buildAnimatedBody) measures its *child's* own
  // size to compute the slide distance, and PhoneSafeCanvas's Align still
  // reports the full available size (it only centres a narrower column
  // *within* that space) — so the slide-in/out distance stays the true
  // window width on a wide window, not the capped content width.
  List<Widget> _buildPages() => [
        PhoneSafeCanvas(child: ProfileScreen()),
        PhoneSafeCanvas(
            child:
                LibraryScreen(initialTabIndex: widget.libraryInitialTabIndex)),
        PhoneSafeCanvas(child: HomeScreen()),
        PhoneSafeCanvas(child: ReaderTabScreen()),
        PhoneSafeCanvas(child: SearchScreen()),
      ];

  // Slides the outgoing page out and the incoming one in, matching the
  // wheel nav's turntable spin.
  late final AnimationController _pageCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _pageAnim = CurvedAnimation(
    parent: _pageCtrl,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _prevIndex = widget.initialIndex;
    _pageCtrl.value = 1; // start settled (no transition on first frame)
    AppTheme.instance.addListener(_onRebuildNeeded);
    AppLocale.instance.addListener(_onRebuildNeeded);
    // Safe to start listening here: the app shell is up, so a cold-start
    // "Open with" file (Telegram, Files, mail, ...) has a Navigator to
    // push the reader into.
    IncomingFileService.instance.init();
    // Same reasoning for a cold-start aykitap://book/<id> deep link — and for
    // a tapped push campaign, which reaches DeepLinkService well before this
    // shell exists and waits there as a pending link until now.
    DeepLinkService.instance.init();
    _scheduleNotificationPrompt();
  }

  /// The one-time notification explanation, deliberately not on the first
  /// frame: it must not land over the splash or the moment Home appears. See
  /// [NotificationPermissionFlow] for why the native prompt is gated behind
  /// it at all.
  void _scheduleNotificationPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(NotificationPermissionFlow.settleDelay, () {
        if (!mounted) return;
        NotificationPermissionFlow.maybeShow(context);
      });
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    AppTheme.instance.removeListener(_onRebuildNeeded);
    AppLocale.instance.removeListener(_onRebuildNeeded);
    super.dispose();
  }

  void _onRebuildNeeded() => setState(() => _pages = _buildPages());

  // Shortest signed step around the ring of tabs — same logic the wheel uses
  // to decide which way to spin, so the page slide and the wheel agree.
  int _circularDir(int from, int to, int n) {
    var x = (to - from) % n;
    if (x < 0) x += n;
    return x <= n / 2 ? 1 : -1;
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    if (index == _readerTabIndex) {
      _onReaderTap();
      return;
    }
    HapticFeedback.lightImpact();
    _switchTo(index);
  }

  void _switchTo(int index) {
    setState(() {
      _prevIndex = _selectedIndex;
      _slideDir = _circularDir(_selectedIndex, index, _pages.length);
      _selectedIndex = index;
    });
    _pageCtrl.forward(from: 0);
  }

  // The wheel's centre "play" tap resumes straight into the last book at the
  // page it was left on — no intermediate "continue reading" card. Only
  // falls through to the reader tab (its empty state) when there's nothing
  // to resume.
  Future<void> _onReaderTap() async {
    HapticFeedback.lightImpact();
    final opened = await openLastReadBook(context);
    if (opened || !mounted) return;
    _switchTo(_readerTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: _buildAnimatedBody(),
      bottomNavigationBar: WheelNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }

  Widget _buildAnimatedBody() {
    return AnimatedBuilder(
      animation: _pageAnim,
      builder: (context, _) {
        final t = _pageAnim.value;
        // ONE stable structure for every state: all pages live permanently
        // in the same Positioned.fill slots (built once, kept alive like an
        // IndexedStack). Only each page's horizontal translation changes —
        // a paint-only transform — so no page is ever rebuilt or disposed
        // mid-navigation. That keeps heavy pages like HomeScreen from
        // re-building on each transition, which is what caused the stutter.
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: List.generate(_pages.length, (i) {
            double dx;
            if (i == _selectedIndex) {
              dx =
                  _slideDir * (1 - t); // incoming: from the _slideDir side to 0
            } else if (i == _prevIndex && t < 1.0) {
              dx = -_slideDir * t; // outgoing: 0 → off the opposite side
            } else {
              dx = 2.0; // parked off-screen (clipped away, invisible)
            }
            return Positioned.fill(
              child: FractionalTranslation(
                translation: Offset(dx, 0),
                child: IgnorePointer(
                  ignoring: i != _selectedIndex,
                  child: _pages[i],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
