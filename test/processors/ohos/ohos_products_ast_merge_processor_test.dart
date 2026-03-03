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
import 'package:flutter_flavorizr/src/processors/ohos/products/ohos_products_processor.dart';
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

  test('Test OhosProductsProcessor AST merges into existing json5 object', () {
    const input = '''
{
  app: {
    name: "DemoApp",
  },
}
''';

    final output = OhosProductsProcessor(
      input: input,
      config: flavorizr,
      logger: logger,
    ).execute();

    final decoded = Map<String, dynamic>.from(json5Decode(output) as Map);
    final products = (decoded['products'] as List).cast<Map>();

    expect(Map<String, dynamic>.from(decoded['app'] as Map)['name'], 'DemoApp');
    expect(products.length, 2);
  });

  test('Test OhosProductsProcessor AST merge is idempotent', () {
    const input = '''
{
  app: {
    name: "DemoApp",
  },
}
''';

    final firstOutput = OhosProductsProcessor(
      input: input,
      config: flavorizr,
      logger: logger,
    ).execute();

    final secondOutput = OhosProductsProcessor(
      input: firstOutput,
      config: flavorizr,
      logger: logger,
    ).execute();

    expect(json5Decode(secondOutput), equals(json5Decode(firstOutput)));
  });

  test('Test OhosProductsProcessor preserves non flavorizr products', () {
    const input = '''
{
  products: [
    {
      name: "external_product",
      signingConfig: "external_sign",
      customField: "keep_me",
    },
    {
      name: "apple_debug",
      signingConfig: "old_sign",
    },
  ],
}
''';

    final output = OhosProductsProcessor(
      input: input,
      config: flavorizr,
      logger: logger,
    ).execute();

    final decoded = Map<String, dynamic>.from(json5Decode(output) as Map);
    final products = (decoded['products'] as List).cast<Map>();

    expect(
      products.any((p) => p['name'] == 'external_product'),
      isTrue,
    );
    expect(
      products
          .firstWhere((p) => p['name'] == 'external_product')['customField'],
      'keep_me',
    );
    expect(
      products.firstWhere((p) => p['name'] == 'apple_debug')['signingConfig'],
      'default',
    );
  });
}
