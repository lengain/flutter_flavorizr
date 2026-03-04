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
        'app': {
          'products': products,
        },
      });
    }

    final dynamic parsed = json5Decode(input!);
    if (parsed is! Map) {
      throw const FormatException(
          'OHOS products target file must be a JSON5 object');
    }

    final root = Map<String, dynamic>.from(parsed);

    final appNode = root['app'];
    if (appNode is Map) {
      final app = Map<String, dynamic>.from(appNode);
      final existingProducts = app['products'] ?? root['products'];
      app['products'] = _mergeProducts(
        existing: existingProducts,
        generated: products,
      );
      root['app'] = app;
      root.remove('products');
      root['modules'] = _mergeModulesTargets(
        existing: root['modules'],
        generatedProductNames:
            products.map((product) => product['name'] as String).toList(),
      );
      _removeLegacyOhosConfig(root);
      return json5Encode(root, space: 2);
    }

    root['products'] =
        _mergeProducts(existing: root['products'], generated: products);
    _removeLegacyOhosConfig(root);
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

  dynamic _mergeModulesTargets({
    required dynamic existing,
    required List<String> generatedProductNames,
  }) {
    if (existing is! List) {
      return existing;
    }

    final generatedTargets = generatedProductNames
        .map(
          (name) => <String, dynamic>{
            'name': name,
            'applyToProducts': [name],
          },
        )
        .toList(growable: false);

    final mergedModules = <dynamic>[];
    for (final item in existing) {
      if (item is! Map) {
        mergedModules.add(item);
        continue;
      }

      final module = Map<String, dynamic>.from(item);
      final moduleName = module['name']?.toString();
      if (moduleName == 'entry' || module['targets'] is List) {
        module['targets'] = _mergeTargets(
          existing: module['targets'],
          generated: generatedTargets,
        );
      }
      mergedModules.add(module);
    }

    return mergedModules;
  }

  List<Map<String, dynamic>> _mergeTargets({
    required dynamic existing,
    required List<Map<String, dynamic>> generated,
  }) {
    final existingTargets = existing is List ? existing : const [];

    final pendingByName = <String, Map<String, dynamic>>{
      for (final target in generated) target['name'] as String: target,
    };

    final merged = <Map<String, dynamic>>[];
    for (final item in existingTargets) {
      if (item is! Map) {
        continue;
      }

      final existingTarget = Map<String, dynamic>.from(item);
      final name = existingTarget['name']?.toString();
      if (name != null && pendingByName.containsKey(name)) {
        merged.add({...existingTarget, ...pendingByName.remove(name)!});
      } else {
        merged.add(existingTarget);
      }
    }

    for (final generatedTarget in generated) {
      final name = generatedTarget['name'] as String;
      if (pendingByName.containsKey(name)) {
        merged.add(pendingByName.remove(name)!);
      }
    }

    return merged;
  }

  void _removeLegacyOhosConfig(Map<String, dynamic> root) {
    final flavorizrNode = root['flavorizr'];
    if (flavorizrNode is! Map) {
      return;
    }

    final flavorizr = Map<String, dynamic>.from(flavorizrNode);
    flavorizr.remove('ohosConfig');
    if (flavorizr.isEmpty) {
      root.remove('flavorizr');
    } else {
      root['flavorizr'] = flavorizr;
    }
  }

  List<Map<String, dynamic>> buildProducts() =>
      config.ohosFlavors.entries.map((entry) {
        final flavor = entry.value.ohos!;
        final rawProduct = Map<String, dynamic>.from(flavor.product);
        final productName = (flavor.name ??
                rawProduct.remove('name') ??
                rawProduct.remove('productName') ??
                entry.key)
            .toString();
        final signingConfig =
            (rawProduct.remove('signingConfig') ?? 'default').toString();
        final compatibleSdkVersion =
            (rawProduct.remove('compatibleSdkVersion') ?? '5.0.5(17)')
                .toString();
        final targetSdkVersion =
            (rawProduct.remove('targetSdkVersion') ?? '5.0.5(17)').toString();
        final runtimeOS =
            (rawProduct.remove('runtimeOS') ?? 'HarmonyOS').toString();
        final bundleName =
            (rawProduct.remove('bundleName') ?? flavor.applicationId)
                .toString();
        final bundleType =
            (rawProduct.remove('bundleType') ?? 'app').toString();
        final icon = rawProduct.remove('icon');
        final label = rawProduct.remove('label');
        final explicitBuildOption = rawProduct.remove('buildOption');

        final product = <String, dynamic>{
          'name': productName,
          'signingConfig': signingConfig,
          'compatibleSdkVersion': compatibleSdkVersion,
          'targetSdkVersion': targetSdkVersion,
          'runtimeOS': runtimeOS,
          'bundleName': bundleName,
          'bundleType': bundleType,
        };
        if (icon != null) {
          product['icon'] = icon.toString();
        }
        if (label != null) {
          product['label'] = label.toString();
        }

        if (explicitBuildOption is Map) {
          final sanitizedBuildOption = _sanitizeMap(
            Map<String, dynamic>.from(explicitBuildOption),
          );
          if (sanitizedBuildOption.isNotEmpty) {
            product['buildOption'] = sanitizedBuildOption;
          }
        } else if (explicitBuildOption != null) {
          product['buildOption'] = explicitBuildOption;
        }

        if (rawProduct.isNotEmpty) {
          product.addAll(rawProduct);
        }

        return product;
      }).toList(growable: false);

  @override
  String toString() => 'OhosProductsProcessor';

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> value) {
    final sanitized = <String, dynamic>{};
    for (final entry in value.entries) {
      final cleaned = _sanitizeNode(entry.value);
      if (cleaned != null) {
        sanitized[entry.key] = cleaned;
      }
    }
    return sanitized;
  }

  dynamic _sanitizeNode(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Map) {
      final cleaned = _sanitizeMap(Map<String, dynamic>.from(value));
      return cleaned.isEmpty ? null : cleaned;
    }
    if (value is List) {
      final cleaned = value
          .map(_sanitizeNode)
          .where((item) => item != null)
          .toList(growable: false);
      return cleaned.isEmpty ? null : cleaned;
    }
    return value;
  }
}
