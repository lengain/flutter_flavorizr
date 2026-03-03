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
import 'package:flutter_flavorizr/src/parser/parser.dart';
import 'package:flutter_flavorizr/src/processors/ohos/config/ohos_config_target_file_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mason_logger/mason_logger.dart';

void main() {
  late Logger logger;
  late Flavorizr flavorizr;

  setUp(() {
    logger = Logger(level: Level.quiet);
    const parser = Parser(
      pubspecPath: 'test_resources/non_existent',
      flavorizrPath: 'test_resources/flavorizr',
    );
    flavorizr = parser.parse();
  });

  test('Test OhosConfigTargetFileProcessor chooses highest priority candidate',
      () {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_config_target_');

    try {
      Directory.current = temp;
      File(K.ohosBuildProfilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('{ app: { name: "ohosProfile" } }');
      File(K.appScopePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('{ app: { bundleName: "demo.app" } }');

      OhosConfigTargetFileProcessor(
        config: flavorizr,
        logger: logger,
      ).execute();

      expect(
        File(K.ohosBuildProfilePath).readAsStringSync().contains('ohosConfig'),
        isTrue,
      );
      expect(
        File(K.appScopePath).readAsStringSync().contains('ohosConfig'),
        isFalse,
      );
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test('Test OhosConfigTargetFileProcessor falls back to generated file', () {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_config_fallback_');

    try {
      Directory.current = temp;
      OhosConfigTargetFileProcessor(
        config: flavorizr,
        logger: logger,
      ).execute();

      final outputFile = File(K.ohosFlavorizrPath);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync().contains('"flavors"'), isTrue);
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });
}
