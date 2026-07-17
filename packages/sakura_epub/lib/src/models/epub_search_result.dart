import 'package:json_annotation/json_annotation.dart';

part 'epub_search_result.g.dart';

@JsonSerializable(explicitToJson: true)
class EpubSearchResult {
  /// The cfi string search result
  String cfi;

  /// The excerpt of the search result
  String excerpt;

  /// Href of the spine item the hit was found in. Match it against
  /// [EpubChapter.href] to name the chapter a result belongs to.
  String? href;

  /// The xpath/XPointer string of the search result
  String? xpath;

  EpubSearchResult({
    required this.cfi,
    required this.excerpt,
    this.href,
    this.xpath,
  });
  factory EpubSearchResult.fromJson(Map<String, dynamic> json) =>
      _$EpubSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$EpubSearchResultToJson(this);
}
