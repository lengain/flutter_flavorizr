/*
 * Copyright (c) 2024 Angelo Cassano
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

import 'package:flutter_flavorizr/src/parser/models/flavors/android/adaptive_icon.dart';
import 'package:flutter_flavorizr/src/parser/models/flavors/android/build_config_field.dart';
import 'package:flutter_flavorizr/src/parser/models/flavors/android/res_value.dart';
import 'package:flutter_flavorizr/src/parser/models/flavors/commons/os.dart';
import 'package:flutter_flavorizr/src/parser/models/flavors/google/firebase/firebase.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ohos.g.dart';

@JsonSerializable(anyMap: true, createToJson: false)
class Ohos extends OS {
  @JsonKey(required: true, disallowNullValue: true)
  final String applicationId;

  @JsonKey(disallowNullValue: true)
  final String? name;

  @JsonKey(disallowNullValue: true)
  final Map<String, dynamic>? target;

  @JsonKey(
    name: 'product',
    readValue: _readProduct,
    disallowNullValue: true,
    defaultValue: {},
  )
  final Map<String, dynamic> product;

  @JsonKey(disallowNullValue: true, defaultValue: {})
  final Map<String, ResValue> resValues;

  @JsonKey(disallowNullValue: true, defaultValue: {})
  final Map<String, BuildConfigField> buildConfigFields;

  @JsonKey(disallowNullValue: true)
  final AdaptiveIcon? adaptiveIcon;

  Ohos({
    required this.applicationId,
    this.name,
    this.target,
    this.product = const {},
    this.resValues = const {},
    this.buildConfigFields = const {},
    super.generateDummyAssets,
    super.firebase,
    super.icon,
    this.adaptiveIcon,
  });

  factory Ohos.fromJson(Map<String, dynamic> json) => _$OhosFromJson(json);

  static Object? _readProduct(Map json, String _) =>
      json['product'] ?? json['customConfig'];
}
