import 'package:aykitap/core/services/daily_reading_goal_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reading time reaches the local fifteen minute goal and persists',
      () async {
    SharedPreferences.setMockInitialValues({});
    final goal = DailyReadingGoalService.instance;
    await goal.load();

    await goal.record(4 * 60);
    expect(goal.completed, isFalse);
    expect(goal.progress, closeTo(4 / 15, 0.001));

    await goal.record(6 * 60);
    expect(goal.secondsToday, 10 * 60);
    expect(goal.completed, isFalse);
    expect(goal.progress, closeTo(2 / 3, 0.001));

    await goal.record(5 * 60);
    expect(goal.secondsToday, 15 * 60);
    expect(goal.completed, isTrue);
    expect(goal.progress, 1.0);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('daily_reading_goal_seconds'), 15 * 60);
  });
}
