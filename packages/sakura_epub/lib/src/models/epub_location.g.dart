// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpubLocation _$EpubLocationFromJson(Map<String, dynamic> json) => EpubLocation(
      startCfi: json['startCfi'] as String,
      endCfi: json['endCfi'] as String,
      startXpath: json['startXpath'] as String?,
      endXpath: json['endXpath'] as String?,
      href: json['href'] as String?,
      tocHref: json['tocHref'] as String?,
      progress: (json['progress'] as num).toDouble(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$EpubLocationToJson(EpubLocation instance) =>
    <String, dynamic>{
      'startCfi': instance.startCfi,
      'endCfi': instance.endCfi,
      'startXpath': instance.startXpath,
      'endXpath': instance.endXpath,
      'href': instance.href,
      'tocHref': instance.tocHref,
      'progress': instance.progress,
      'page': instance.page,
      'totalPages': instance.totalPages,
    };
