import 'package:flutter/material.dart';

/// Fades + slides its child in from below as it's built — [SliverList]
/// builds lazily, so this doubles as a "settle in as you scroll to it"
/// effect rather than the whole list popping in at once. The stagger is
/// capped at 300ms so a long list doesn't leave later rows waiting on a
/// delay that's already outlasted its purpose.
class StaggerFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerFadeIn({super.key, required this.index, required this.child});

  @override
  State<StaggerFadeIn> createState() => _StaggerFadeInState();
}

class _StaggerFadeInState extends State<StaggerFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_fade);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 300));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
