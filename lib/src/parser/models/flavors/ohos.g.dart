// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ohos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ohos _$OhosFromJson(Map json) {
  $checkKeys(
    json,
    disallowNullValues: const [
      'firebase',
      'icon',
      'bundleName',
      'name',
      'target',
      'product',
      'resValues',
      'buildConfigFields',
      'adaptiveIcon'
    ],
  );
  return Ohos(
    bundleName: json['bundleName'] as String?,
    name: json['name'] as String?,
    target: (json['target'] as Map?)?.map(
      (k, e) => MapEntry(k as String, e),
    ),
    product: (Ohos._readProduct(json, 'product') as Map?)?.map(
          (k, e) => MapEntry(k as String, e),
        ) ??
        {},
    resValues: (json['resValues'] as Map?)?.map(
          (k, e) => MapEntry(k as String,
              ResValue.fromJson(Map<String, dynamic>.from(e as Map))),
        ) ??
        {},
    buildConfigFields: (json['buildConfigFields'] as Map?)?.map(
          (k, e) => MapEntry(k as String,
              BuildConfigField.fromJson(Map<String, dynamic>.from(e as Map))),
        ) ??
        {},
    generateDummyAssets: json['generateDummyAssets'] as bool? ?? true,
    firebase: json['firebase'] == null
        ? null
        : Firebase.fromJson(Map<String, dynamic>.from(json['firebase'] as Map)),
    icon: json['icon'] as String?,
    adaptiveIcon: json['adaptiveIcon'] == null
        ? null
        : AdaptiveIcon.fromJson(
            Map<String, dynamic>.from(json['adaptiveIcon'] as Map)),
  );
}
