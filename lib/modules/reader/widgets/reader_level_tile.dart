import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A vertical "fill level" control (TZ §12.4 reference design): a rounded
/// tile whose bottom band fills to the current value, with the icon pinned at
/// the bottom of the tile. Drag or tap anywhere in the tile to set a new
/// value — there's no separate slider track, the tile *is* the slider.
class ReaderLevelTile extends StatelessWidget {
  final Widget Function(Color color) iconBuilder;
  final String label;

  /// Current value read out as text at the top of the tile (e.g. "20", "1.5",
  /// "100%"), so the reader can see the exact setting, not just the fill band.
  final String? valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const ReaderLevelTile({
    super.key,
    required this.iconBuilder,
    required this.label,
    this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  static const _height = 120.0;
  // Narrower than the row slot it sits in (each tile is inside an Expanded),
  // and centred there — a full-width tile per slot read as too wide/blocky.
  static const _width = 58.0;
  // The icon sits in this bottom band; once the fill rises past it the icon
  // reads white (sitting on the accent), otherwise it stays muted.
  static const _iconBandHeight = 40.0;
  // The value readout sits in this top band; once the fill rises high enough
  // to reach it, its text flips to white the same way the icon does.
  static const _valueBandHeight = 28.0;

  double get _fraction => ((value - min) / (max - min)).clamp(0.0, 1.0);

  void _handle(Offset localPosition) {
    final frac = (1 - (localPosition.dy / _height)).clamp(0.0, 1.0);
    onChanged(min + frac * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    final fillHeight = _height * _fraction;
    // White while the fill covers the icon band, muted while it's above it.
    final iconOnFill = fillHeight >= _iconBandHeight * 0.6;
    // The value badge sits at the top, so the fill only reaches it near full.
    final valueOnFill = fillHeight >= (_height - _valueBandHeight * 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handle(d.localPosition),
          onVerticalDragUpdate: (d) => _handle(d.localPosition),
          // A border (plus the rounded corners) keeps the tile's outline
          // visible in both themes — otherwise the empty part is invisible
          // on the light sheet, where the card fill is white on white.
          child: Container(
            height: _height,
            width: _width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: fillHeight,
                  child: ColoredBox(color: AppColors.primary),
                ),
                // Value readout pinned at the top of the tile.
                if (valueText != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: _valueBandHeight,
                    child: Center(
                      child: Text(
                        valueText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: valueOnFill ? Colors.white : AppColors.grey1,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Icon fixed at the bottom of the tile.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _iconBandHeight,
                  child: Center(
                      child: iconBuilder(
                          iconOnFill ? Colors.white : AppColors.grey2)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Fixed two-line height so a one-line label ("Parlaklyk") reserves the
        // same space as a two-line one ("Şrift ölçegi") — keeps every tile the
        // same total height and aligned.
        SizedBox(
          height: 26,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppColors.grey2,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.2),
          ),
        ),
      ],
    );
  }
}
