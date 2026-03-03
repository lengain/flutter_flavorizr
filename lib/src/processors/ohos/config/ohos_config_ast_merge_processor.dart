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

import 'package:flutter_flavorizr/src/processors/commons/string_processor.dart';
import 'package:flutter_flavorizr/src/processors/ohos/config/ohos_config_processor.dart';
import 'package:json5/json5.dart';

class OhosConfigAstMergeProcessor extends StringProcessor {
  static const _flavorizrNode = 'flavorizr';
  static const _ohosNode = 'ohosConfig';
  static const _schemaVersionNode = 'schemaVersion';
  static const _flavorsNode = 'flavors';

  OhosConfigAstMergeProcessor({
    super.input,
    required super.config,
    required super.logger,
  });

  @override
  String execute() {
    final generated = OhosConfigProcessor(
      config: config,
      logger: logger,
    ).buildFlavorsConfig();

    final dynamic parsed = (input == null || input!.trim().isEmpty)
        ? <String, dynamic>{}
        : json5Decode(input!);

    if (parsed is! Map) {
      throw const FormatException(
          'OHOS config target file must be a JSON5 object');
    }

    final root = Map<String, dynamic>.from(parsed as Map);
    final flavorizrNode = Map<String, dynamic>.from(
        (root[_flavorizrNode] as Map?) ?? <String, dynamic>{});

    flavorizrNode[_ohosNode] = {
      _schemaVersionNode: 1,
      _flavorsNode: generated,
    };

    root[_flavorizrNode] = flavorizrNode;

    return json5Encode(root, space: 2);
  }

  @override
  String toString() => 'OhosConfigAstMergeProcessor';
}
