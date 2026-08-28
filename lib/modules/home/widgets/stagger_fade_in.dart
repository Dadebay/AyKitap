import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

/// One-shot entrance for a newly loaded Home section.
///
/// Home owns the lifecycle: this widget is only mounted when a successful
/// collection response arrives, so scrolling away and back does not replay
/// the motion. A manual refresh replaces the sections and intentionally gives
/// the fresh result one new entrance. [AutomaticKeepAliveClientMixin] carries
/// that same "plays once" guarantee into a lazy sliver (`SliverList.builder`)
/// too — without it, scrolling a row far enough to leave the cache extent
/// disposes this State, and scrolling back would otherwise replay the
/// entrance for a section the user has already seen.
class StaggerFadeIn extends StatefulWidget {
  final int index;
  final Widget child;

  /// Extra lead-in added on top of the (clamped) index-based delay —
  /// unclamped, unlike [index]'s own contribution. For a [StaggerFadeIn]
  /// nested inside another one (a book card inside a section that itself
  /// staggers in): without this, the inner widget's delay timer starts
  /// counting from its own mount time, not from when the outer section
  /// actually becomes visible — since both run on the same short
  /// [AppMotion.sectionEntrance] budget, the inner entrance would usually
  /// finish *before* the outer section's own fade even starts, and the
  /// user would never see it. Pass the outer instance's own resolved delay
  /// here so the inner cascade starts in step with it.
  final Duration extraDelay;

  /// Pixel distance the child travels from as it fades in, arriving at its
  /// laid-out position when the entrance completes. Defaults to a 10px
  /// upward slide; a horizontal [ListView] row passes a rightward one
  /// (e.g. `Offset(20, 0)`) so its cards slide in from the direction the
  /// row itself scrolls toward, rather than up.
  final Offset slideFrom;

  const StaggerFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.extraDelay = Duration.zero,
    this.slideFrom = const Offset(0, 10),
  });

  /// The clamped index-based delay a plain (no [extraDelay]) instance at
  /// [index] would use — for a caller that needs to hand that same value
  /// to a *nested* instance's [extraDelay], without duplicating the clamp
  /// math [_StaggerFadeInState.didChangeDependencies] applies internally.
  static Duration delayFor(int index) => Duration(
      milliseconds: (index * AppMotion.sectionStagger.inMilliseconds)
          .clamp(0, AppMotion.sectionEntrance.inMilliseconds));

  @override
  State<StaggerFadeIn> createState() => _StaggerFadeInState();
}

class _StaggerFadeInState extends State<StaggerFadeIn>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.sectionEntrance,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOut);
  Timer? _delay;
  bool _configured = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    _delay = Timer(
      widget.extraDelay + StaggerFadeIn.delayFor(widget.index),
      _controller.forward,
    );
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _fade,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          // A fixed pixel offset, not a fractional [SlideTransition] one —
          // the same travel distance regardless of the child's own size.
          offset: widget.slideFrom * (1 - _fade.value),
          child: child,
        ),
      ),
    );
  }
}
