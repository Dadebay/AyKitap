import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom action bar for adding a book request.
class NewBookRequestBar extends StatefulWidget {
  const NewBookRequestBar({
    required this.onPressed,
    required this.pulse,
    super.key,
  });

  final VoidCallback onPressed;
  final bool pulse;

  @override
  State<NewBookRequestBar> createState() => _NewBookRequestBarState();
}

class _NewBookRequestBarState extends State<NewBookRequestBar>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _press;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      value: 1,
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _press.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    _press.animateTo(
      pressed ? .97 : 1,
      duration: Duration(milliseconds: pressed ? 100 : 220),
      curve: pressed ? Curves.easeOut : Curves.elasticOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
              CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic)),
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, _glow]),
        builder: (context, child) {
          final glowT = widget.pulse ? _glow.value : 0.0;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .12 + glowT * .14),
                  blurRadius: 26 + glowT * 14,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Transform.scale(
              scale: _press.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  onTapDown: (_) => _setPressed(true),
                  onTapUp: (_) => _setPressed(false),
                  onTapCancel: () => _setPressed(false),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: .35 + glowT * .25,
                          ),
                          blurRadius: 16 + glowT * 12,
                          spreadRadius: glowT * 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          ProfileStrings.newBookRequest,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
