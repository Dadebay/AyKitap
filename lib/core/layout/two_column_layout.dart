import 'package:flutter/widgets.dart';

/// Phone: [left] then [right] stacked in one column. Tablet (700dp+): the two
/// lists side by side. The lists carry their own vertical spacers, so the
/// caller controls rhythm in both layouts.
class TwoColumnLayout extends StatelessWidget {
  const TwoColumnLayout({
    super.key,
    required this.left,
    required this.right,
    this.gap = 16,
    this.columnGap = 20,
  });

  final List<Widget> left;
  final List<Widget> right;

  /// Vertical space between the two stacks on a phone.
  final double gap;

  /// Horizontal space between the two columns on a tablet.
  final double columnGap;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 700;

  @override
  Widget build(BuildContext context) {
    if (!isWide(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...left,
          if (left.isNotEmpty && right.isNotEmpty) SizedBox(height: gap),
          ...right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: left)),
        SizedBox(width: columnGap),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: right)),
      ],
    );
  }
}

/// A list of variable-height cards. Phone: one column. Tablet (700dp+): two
/// columns, items alternating left/right (1 left, 2 right, 3 left…), so the
/// reading order stays top-to-bottom row by row and a short card never leaves
/// a hole next to a tall one.
class TwoColumnList extends StatelessWidget {
  const TwoColumnList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 14,
    this.columnGap = 16,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double spacing;
  final double columnGap;

  List<Widget> _stack(BuildContext context, Iterable<int> indexes) => [
        for (final i in indexes) ...[
          if (i != indexes.first) SizedBox(height: spacing),
          itemBuilder(context, i),
        ],
      ];

  @override
  Widget build(BuildContext context) {
    final all = List<int>.generate(itemCount, (i) => i);
    if (!TwoColumnLayout.isWide(context)) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _stack(context, all));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _stack(context, all.where((i) => i.isEven)))),
        SizedBox(width: columnGap),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _stack(context, all.where((i) => i.isOdd)))),
      ],
    );
  }
}
