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

import 'dart:io';

import 'package:flutter_flavorizr/src/parser/models/flavorizr.dart';
import 'package:flutter_flavorizr/src/processors/commons/abstract_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:json5/json5.dart';
import 'package:mason_logger/mason_logger.dart';

class OhosConfigTargetFileProcessor extends AbstractProcessor<void> {
  static final legacyCandidatePaths = [
    K.ohosAppScopePath,
    K.ohosEntryModulePath,
    K.appScopePath,
    K.entryModulePath,
  ];

  OhosConfigTargetFileProcessor({
    required Flavorizr config,
    required Logger logger,
  }) : super(config, logger: logger);

  @override
  void execute() {
    _removeLegacyOhosConfigFromProjectFiles();
  }

  void _removeLegacyOhosConfigFromProjectFiles() {
    for (final path in legacyCandidatePaths) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) {
        continue;
      }
      final dynamic parsed = json5Decode(content);
      if (parsed is! Map) {
        continue;
      }
      final root = Map<String, dynamic>.from(parsed);
      if (_removeLegacyOhosConfig(root)) {
        file.writeAsStringSync(json5Encode(root, space: 2));
      }
    }
  }

  bool _removeLegacyOhosConfig(Map<String, dynamic> root) {
    final flavorizrNode = root['flavorizr'];
    if (flavorizrNode is! Map) {
      return false;
    }

    final flavorizr = Map<String, dynamic>.from(flavorizrNode);
    final hadOhosConfig = flavorizr.remove('ohosConfig') != null;
    if (!hadOhosConfig) {
      return false;
    }

    if (flavorizr.isEmpty) {
      root.remove('flavorizr');
    } else {
      root['flavorizr'] = flavorizr;
    }
    return true;
  }

  @override
  String toString() => 'OhosConfigTargetFileProcessor';
}
