import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// One labelled action in a reader's bottom toolbar — icon in a rounded
/// "well", caption below. Shared by the EPUB and PDF bottom bars, which used
/// to each carry an identical copy.
class ReaderToolbarBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final Color labelColor;
  final Color wellColor;
  final VoidCallback onTap;

  /// Landscape: caption hidden and the well tightened, so the bar fits the
  /// shorter screen. The tap target keeps the full row height either way.
  final bool compact;

  const ReaderToolbarBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.labelColor,
    required this.wellColor,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: compact ? 5 : 7),
                  decoration: BoxDecoration(
                    color: wellColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: FittedBox(
                        child: HugeIcon(icon: icon, color: color, size: 22)),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: labelColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
