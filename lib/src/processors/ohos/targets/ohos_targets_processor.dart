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

import 'package:flutter_flavorizr/src/processors/ohos/ohos_json_mapping_utils.dart';
import 'package:flutter_flavorizr/src/processors/commons/string_processor.dart';
import 'package:json5/json5.dart';

class OhosTargetsProcessor extends StringProcessor {
  static const _mainResourcesDirectory = './src/main/resources';

  OhosTargetsProcessor({
    super.input,
    required super.config,
    required super.logger,
  });

  @override
  String execute() {
    final targets = buildTargets();

    if (input == null || input!.trim().isEmpty) {
      return const JsonEncoder.withIndent('  ').convert({
        'targets': targets,
      });
    }

    final dynamic parsed = json5Decode(input!);
    if (parsed is! Map) {
      throw const FormatException(
        'OHOS entry build-profile target file must be a JSON5 object',
      );
    }

    final root = Map<String, dynamic>.from(parsed);
    root['targets'] =
        _mergeTargets(existing: root['targets'], generated: targets);
    return json5Encode(root, space: 2);
  }

  List<Map<String, dynamic>> buildTargets() =>
      config.ohosFlavors.entries.map((entry) {
        final flavorName = entry.key;
        final ohos = entry.value.ohos!;
        final name = _resolveTargetName(entry.key, ohos.name, ohos.product);
        final target = ohos.target;

        if (target == null) {
          return <String, dynamic>{
            'name': name,
            'source': {
              'pages': ['pages/Index'],
              'sourceRoots': ['./src/$name'],
            },
            'resource': {
              'directories': [
                './src/main/$name/resources',
                _mainResourcesDirectory,
              ],
            },
          };
        }

        final generated = <String, dynamic>{'name': name};
        generated.addAll(_readAdditionalFields(target));
        final source = _readSource(flavorName, target);
        if (source.isNotEmpty) {
          generated['source'] = source;
        }

        final resource = _readResource(flavorName, target);
        if (resource.isNotEmpty) {
          generated['resource'] = resource;
        }
        return generated;
      }).toList(growable: false);

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
      if (name == null || !pendingByName.containsKey(name)) {
        merged.add(existingTarget);
        continue;
      }

      final generatedTarget = pendingByName.remove(name)!;
      final target = Map<String, dynamic>.from(existingTarget)..['name'] = name;

      if (generatedTarget.containsKey('source')) {
        target['source'] = generatedTarget['source'];
      } else {
        target.remove('source');
      }

      if (generatedTarget.containsKey('resource')) {
        target['resource'] = generatedTarget['resource'];
      } else {
        target.remove('resource');
      }

      for (final entry in generatedTarget.entries) {
        final key = entry.key;
        if (key == 'name' || key == 'source' || key == 'resource') {
          continue;
        }
        target[key] = OhosJsonMappingUtils.mergeNode(target[key], entry.value);
      }

      merged.add(target);
    }

    for (final generatedTarget in generated) {
      final name = generatedTarget['name'] as String;
      if (pendingByName.containsKey(name)) {
        merged.add(pendingByName.remove(name)!);
      }
    }

    return merged;
  }

  Map<String, dynamic> _readSource(
    String flavorName,
    Map<String, dynamic> target,
  ) {
    final sourceNode = target['source'];
    if (sourceNode == null) {
      return const {};
    }
    if (sourceNode is! Map) {
      throw FormatException(
        'Invalid `flavors.$flavorName.ohos.target.source`: expected object.',
      );
    }

    final source = <String, dynamic>{};
    if (sourceNode.containsKey('pages')) {
      source['pages'] = _readStringList(
        flavorName: flavorName,
        keyPath: 'target.source.pages',
        value: sourceNode['pages'],
      );
    }

    if (sourceNode.containsKey('sourceRoots')) {
      source['sourceRoots'] = _readStringList(
        flavorName: flavorName,
        keyPath: 'target.source.sourceRoots',
        value: sourceNode['sourceRoots'],
      );
    }

    return source;
  }

  Map<String, dynamic> _readResource(
    String flavorName,
    Map<String, dynamic> target,
  ) {
    final resourceNode = target['resource'];
    if (resourceNode == null) {
      return const {};
    }
    if (resourceNode is! Map) {
      throw FormatException(
        'Invalid `flavors.$flavorName.ohos.target.resource`: expected object.',
      );
    }

    final resource = <String, dynamic>{};
    if (resourceNode.containsKey('directories')) {
      final directories = _readStringList(
        flavorName: flavorName,
        keyPath: 'target.resource.directories',
        value: resourceNode['directories'],
      );
      if (!directories.contains(_mainResourcesDirectory)) {
        directories.add(_mainResourcesDirectory);
      }
      resource['directories'] = directories;
    }

    return resource;
  }

  List<String> _readStringList({
    required String flavorName,
    required String keyPath,
    required dynamic value,
  }) {
    if (value is! List) {
      throw FormatException(
        'Invalid `flavors.$flavorName.ohos.$keyPath`: expected string array.',
      );
    }

    final result = <String>[];
    for (final item in value) {
      if (item is! String) {
        throw FormatException(
          'Invalid `flavors.$flavorName.ohos.$keyPath`: expected string array.',
        );
      }
      result.add(item);
    }
    return result;
  }

  Map<String, dynamic> _readAdditionalFields(Map<String, dynamic> target) {
    return OhosJsonMappingUtils.copyAdditionalFields(
      target,
      excludedKeys: {'source', 'resource'},
    );
  }

  String _resolveTargetName(
    String flavorKey,
    String? ohosName,
    Map<String, dynamic> product,
  ) {
    final rawProduct = Map<String, dynamic>.from(product);
    return (ohosName ??
            rawProduct['name'] ??
            rawProduct['productName'] ??
            flavorKey)
        .toString();
  }

  @override
  String toString() => 'OhosTargetsProcessor';
}
