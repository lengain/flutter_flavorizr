/*
 * Copyright (c) 2026 Angelo Cassano
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

import 'dart:convert';

import 'package:flutter_flavorizr/src/processors/commons/string_processor.dart';

class OhosConfigProcessor extends StringProcessor {
  OhosConfigProcessor({
    super.input,
    required super.config,
    required super.logger,
  });

  @override
  String execute() {
    return const JsonEncoder.withIndent('  ').convert({
      'flavors': buildFlavorsConfig(),
    });
  }

  List<Map<String, dynamic>> buildFlavorsConfig() =>
      config.ohosFlavors.entries.map((entry) {
        final flavor = entry.value.ohos!;
        return {
          'name': entry.key,
          'applicationId': flavor.applicationId,
          'agconnect': flavor.agconnect?.config,
          'customConfig': flavor.customConfig,
          'resValues': flavor.resValues.map(
            (key, value) => MapEntry(
              key,
              {
                'type': value.type,
                'value': value.value,
              },
            ),
          ),
          'buildConfigFields': flavor.buildConfigFields.map(
            (key, value) => MapEntry(
              key,
              {
                'type': value.type,
                'value': value.value,
              },
            ),
          ),
        };
      }).toList(growable: false);

  @override
  String toString() => 'OhosConfigProcessor';
}
