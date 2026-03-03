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

import 'package:flutter_flavorizr/src/parser/models/flavorizr.dart';
import 'package:flutter_flavorizr/src/parser/parser.dart';
import 'package:flutter_flavorizr/src/processors/ohos/config/ohos_config_ast_merge_processor.dart';
import 'package:json5/json5.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mason_logger/mason_logger.dart';

void main() {
  late Flavorizr flavorizr;
  late Logger logger;

  setUp(() {
    logger = Logger(level: Level.quiet);
    const parser = Parser(
      pubspecPath: 'test_resources/non_existent',
      flavorizrPath: 'test_resources/flavorizr',
    );
    flavorizr = parser.parse();
  });

  test('Test OhosConfigAstMergeProcessor merges into existing json5 object',
      () {
    const input = '''
{
  app: {
    name: "DemoApp",
  },
  flavorizr: {
    foo: 1,
  },
}
''';

    final output = OhosConfigAstMergeProcessor(
      input: input,
      config: flavorizr,
      logger: logger,
    ).execute();

    final decoded = Map<String, dynamic>.from(json5Decode(output) as Map);
    final flavorizrNode =
        Map<String, dynamic>.from(decoded['flavorizr'] as Map);
    final ohosNode =
        Map<String, dynamic>.from(flavorizrNode['ohosConfig'] as Map);
    final flavors = (ohosNode['flavors'] as List).cast<Map>();

    expect(Map<String, dynamic>.from(decoded['app'] as Map)['name'], 'DemoApp');
    expect(flavorizrNode['foo'], 1);
    expect(ohosNode['schemaVersion'], 1);
    expect(flavors.length, 2);
  });

  test('Test OhosConfigAstMergeProcessor is idempotent', () {
    const input = '''
{
  app: {
    name: "DemoApp",
  },
}
''';

    final processor = OhosConfigAstMergeProcessor(
      input: input,
      config: flavorizr,
      logger: logger,
    );

    final firstOutput = processor.execute();
    final secondOutput = OhosConfigAstMergeProcessor(
      input: firstOutput,
      config: flavorizr,
      logger: logger,
    ).execute();

    final firstDecoded = json5Decode(firstOutput);
    final secondDecoded = json5Decode(secondOutput);

    expect(secondDecoded, equals(firstDecoded));
  });
}
