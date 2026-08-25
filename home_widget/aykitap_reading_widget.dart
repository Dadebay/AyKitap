import 'package:home_widget_generator/home_widget_generator.dart';

/// Native target scaffolding. Its generated widget source is intentionally
/// replaced by the platform-specific designs in the app targets.
@HomeWidget(
  name: 'AykitapReadingWidget',
  android: HomeWidgetAndroidConfiguration(),
  iOS: HomeWidgetIOSConfiguration(groupId: 'group.com.aykitap.aykitap'),
  widget: HWText.fixed('Aýkitap'),
)
class AykitapReadingWidget {}
