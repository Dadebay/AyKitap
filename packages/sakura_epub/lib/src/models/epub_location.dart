import 'package:json_annotation/json_annotation.dart';

part 'epub_location.g.dart';

@JsonSerializable(explicitToJson: true)
class EpubLocation {
  /// Start cfi string of the page
  String startCfi;

  /// End cfi string of the page
  String endCfi;

  /// Start xpath/XPointer string of the page
  String? startXpath;

  /// End xpath/XPointer string of the page
  String? endXpath;

  /// Spine href of the page currently on screen, e.g. `index_split_003.xhtml`.
  /// Match it against [EpubChapter.href] to work out the current chapter.
  String? href;

  /// Progress percentage of location, value between 0.0 and 1.0
  double progress;

  EpubLocation({
    required this.startCfi,
    required this.endCfi,
    this.startXpath,
    this.endXpath,
    this.href,
    required this.progress,
  });
  factory EpubLocation.fromJson(Map<String, dynamic> json) =>
      _$EpubLocationFromJson(json);
  Map<String, dynamic> toJson() => _$EpubLocationToJson(this);
}
