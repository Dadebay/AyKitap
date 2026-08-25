part of 'wheel_nav_bar.dart';

// Every geometry/timing constant [_WheelNavBarState] and its part files
// (wheel_nav_bar_gestures.dart, wheel_nav_bar_icons.dart) tune the wheel
// with. Split out purely to keep wheel_nav_bar.dart under the 200-line
// limit — these used to be `static const` fields on _WheelNavBarState;
// as library-level (`part of`) consts instead, every part file reaches them
// by the same bare name, with no `_WheelNavBarState.` qualification needed.
// Same names, same values, same privacy (leading `_` still scopes them to
// this library) — nothing here changes what any of them evaluate to.

// Profile, Kitaplyk, Ana sayfa (centre), Çytalka (reader), Poisk — must stay
// in lockstep with _buildPages() in MainNavScreen.
const _icons = [
  HugeIcons.strokeRoundedUser,
  HugeIcons.strokeRoundedLibrary,
  HugeIcons.strokeRoundedHome01,
  HugeIcons.strokeRoundedPlay,
  HugeIcons.strokeRoundedSearch01,
];

// The profile tab's slot in [_icons] — [_WheelNavBarIcons] swaps its
// HugeIcons.strokeRoundedUser glyph for the signed-in user's actual
// [ProfileAvatar] once one is set (see [ProfileAvatarService]).
const _profileTabIndex = 0;

// ── Geometry ─────────────────────────────────────────────────────────────
const _barHeight = 42.0;
const _fabSize = 56.0;
const _iconBoxSize = 40.0;
// Minimum tappable square per icon — the visible icon can be smaller, this
// just widens the invisible hit area to a finger-friendly size (~Apple's
// 44pt guidance, with a little extra).
const _minTapTarget = 52.0;

// The dome and the icon ring share the same centre (diskCenterY = _diskR -
// _domeLift). Growing _diskR and _domeLift by the same amount enlarges the
// visible dome circle while keeping that centre — and therefore every
// icon's position — exactly where it was.
const _diskR = 400.0; // radius of the dome — a true circle, not an ellipse
const _pathR =
    365.0; // radius of the ring the icons travel on — right up against the rim, so unselected icons sit at the dome's outer edge rather than buried near its centre
// Radius the fully-selected icon rides at — a bit past _pathR so it still
// pokes out over the rim, but well short of _diskR so it doesn't perch too
// high above the bar. Lower this to drop the selected icon further down.
const _selectedR = 390.0;
const _stepRad = 14.0 * math.pi / 220.0; // angle between two icons
// Keeps diskCenterY (_diskR - _domeLift) at 170, the value that lands the
// ring in the visible window — must track _diskR so the icons don't drift
// off-screen when the dome size changes.
const _domeLift = 40.0; // how far the dome pokes above the bar's top edge

// Extra height added on top of the bar purely so the raised dome/icons fall
// inside the widget's hit-test box (see build). Covers the full dome lift
// plus a small margin; icons stay put visually, they just become tappable.
const _domeHitOverhang = _domeLift + 6;

// Only icons whose angle from the top is inside this window are drawn.
// With 5 icons the farthest slot is still 2 steps away (2 * _stepRad ≈
// 1.40rad, same as with 4), so both bounds must clear that to keep every
// icon fully opaque at rest.
const _windowRad = 1.90;
const _fadeStart = 1.60;

// ── Drag ─────────────────────────────────────────────────────────────────
// How far, horizontally, one slot travels at the top of the ring:
// d(cx)/d(index) is r·sin'(0)·stepRad = r·stepRad. Converting the finger's
// dx through this is what makes the icons track the finger 1:1 instead of
// at some arbitrary made-up rate.
const _pxPerStep = _pathR * _stepRad;
// Past this speed a release counts as a flick: the wheel carries on to the
// next slot in the direction it was thrown even if the finger never
// dragged a full one.
const _flingVelocity = 320.0; // px/s
