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
import 'package:json5/json5.dart';

class OhosProductsProcessor extends StringProcessor {
  OhosProductsProcessor({
    super.input,
    required super.config,
    required super.logger,
  });

  @override
  String execute() {
    final products = buildProducts();

    if (input == null || input!.trim().isEmpty) {
      return const JsonEncoder.withIndent('  ').convert({
        'products': products,
      });
    }

    final dynamic parsed = json5Decode(input!);
    if (parsed is! Map) {
      throw const FormatException(
          'OHOS products target file must be a JSON5 object');
    }

    final root = Map<String, dynamic>.from(parsed as Map);
    root['products'] = _mergeProducts(
      existing: root['products'],
      generated: products,
    );
    return json5Encode(root, space: 2);
  }

  List<Map<String, dynamic>> _mergeProducts({
    required dynamic existing,
    required List<Map<String, dynamic>> generated,
  }) {
    if (existing is! List) {
      return generated;
    }

    final pendingByName = <String, Map<String, dynamic>>{
      for (final product in generated) product['name'] as String: product,
    };

    final merged = <Map<String, dynamic>>[];
    for (final item in existing) {
      if (item is! Map) {
        continue;
      }

      final existingProduct = Map<String, dynamic>.from(item);
      final name = existingProduct['name']?.toString();
      if (name != null && pendingByName.containsKey(name)) {
        merged.add(pendingByName.remove(name)!);
      } else {
        merged.add(existingProduct);
      }
    }

    for (final generatedProduct in generated) {
      final name = generatedProduct['name'] as String;
      if (pendingByName.containsKey(name)) {
        merged.add(pendingByName.remove(name)!);
      }
    }

    return merged;
  }

  List<Map<String, dynamic>> buildProducts() =>
      config.ohosFlavors.entries.map((entry) {
        final flavor = entry.value.ohos!;
        final rawConfig = Map<String, dynamic>.from(flavor.customConfig);
        final productName =
            (rawConfig.remove('productName') ?? entry.key).toString();
        final signingConfig =
            (rawConfig.remove('signingConfig') ?? 'default').toString();

        return {
          'name': productName,
          'signingConfig': signingConfig,
          'buildOption': {
            'arkOptions': {
              'buildProfileFields': rawConfig,
            },
          },
        };
      }).toList(growable: false);

  @override
  String toString() => 'OhosProductsProcessor';
}
