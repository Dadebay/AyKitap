import '../../../core/localization/strings/reader_strings.dart';
import '../provider/reader_enums.dart';

/// Artwork lives in assets/icons/reader/, in the same order as
/// [ReaderPageTransition]. The PNGs are transparent silhouettes, so they get
/// tinted at paint time to follow the selected/idle state (see
/// [TransitionTile]). Shared by [PageTransitionRow] and [PageTransitionSheet].
const transitionIcons = {
  ReaderPageTransition.slide: 'assets/icons/reader/transition_slide.png',
  ReaderPageTransition.curl: 'assets/icons/reader/transition_curl.png',
  ReaderPageTransition.overlay: 'assets/icons/reader/transition_overlay.png',
  ReaderPageTransition.scroll: 'assets/icons/reader/transition_scroll.png',
  ReaderPageTransition.shift: 'assets/icons/reader/transition_shift.png',
  ReaderPageTransition.none: 'assets/icons/reader/transition_none.png',
};

String transitionLabel(ReaderPageTransition t) => switch (t) {
      ReaderPageTransition.slide => ReaderStrings.transitionSlide,
      ReaderPageTransition.curl => ReaderStrings.transitionCurl,
      ReaderPageTransition.overlay => ReaderStrings.transitionOverlay,
      ReaderPageTransition.scroll => ReaderStrings.transitionScroll,
      ReaderPageTransition.shift => ReaderStrings.transitionShift,
      ReaderPageTransition.none => ReaderStrings.transitionNone,
    };
