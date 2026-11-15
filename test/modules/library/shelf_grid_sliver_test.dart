import 'package:aykitap/modules/library/widgets/shelf_grid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shelf builds only nearby rows', (tester) async {
    final built = <int>{};
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          slivers: [
            ShelfGridSliver(
              itemCount: 300,
              itemBuilder: (context, index) {
                built.add(index);
                return Text('book $index');
              },
            ),
          ],
        ),
      ),
    ));

    expect(built, contains(0));
    expect(built.length, lessThan(60));
    expect(built, isNot(contains(299)));

    controller.jumpTo(1600);
    await tester.pump();
    expect(built.length, greaterThan(3));
    expect(built, isNot(contains(299)));
  });
}
