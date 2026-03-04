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
import 'package:flutter_flavorizr/src/processors/ohos/targets/ohos_targets_processor.dart';
import 'package:flutter_flavorizr/src/processors/ohos/targets/ohos_targets_target_file_processor.dart';
import 'package:flutter_flavorizr/src/processors/processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
import 'package:mason_logger/mason_logger.dart';

void main() {
  late Logger logger;

  setUp(() {
    logger = Logger(level: Level.quiet);
  });

  test('Test OhosTargetsProcessor maps configured and default targets', () {
    final config = Flavorizr.parse('''
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      name: "apple_debug"
      target:
        source:
          pages:
            - "pages/Index"
          sourceRoots:
            - "./src/apple_debug"
        resource:
          directories:
            - "./src/main/apple_debug/resources"
        output:
          artifactName: "apple_hap"
  banana:
    app:
      name: "Banana App"
    ohos:
      applicationId: "com.example.banana.ohos"
      name: "banana_release"
''');

    final processor = OhosTargetsProcessor(config: config, logger: logger);
    final decoded =
        Map<String, dynamic>.from(json5Decode(processor.execute()) as Map);
    final targets = (decoded['targets'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);

    final apple =
        targets.firstWhere((target) => target['name'] == 'apple_debug');
    final banana =
        targets.firstWhere((target) => target['name'] == 'banana_release');

    final appleSource = Map<String, dynamic>.from(apple['source'] as Map);
    final appleResource = Map<String, dynamic>.from(apple['resource'] as Map);
    final appleOutput = Map<String, dynamic>.from(apple['output'] as Map);
    expect(appleSource['pages'], <String>['pages/Index']);
    expect(appleSource['sourceRoots'], <String>['./src/apple_debug']);
    expect(appleResource['directories'], <String>[
      './src/main/apple_debug/resources',
      './src/main/resources',
    ]);
    expect(appleOutput['artifactName'], 'apple_hap');

    final bananaSource = Map<String, dynamic>.from(banana['source'] as Map);
    final bananaResource = Map<String, dynamic>.from(banana['resource'] as Map);
    expect(bananaSource['pages'], <String>['pages/Index']);
    expect(bananaSource['sourceRoots'], <String>['./src/banana_release']);
    expect(bananaResource['directories'], <String>[
      './src/main/banana_release/resources',
      './src/main/resources',
    ]);
  });

  test('Test OhosTargetsProcessor merges by name and keeps unknown fields', () {
    final config = Flavorizr.parse('''
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      name: "apple_debug"
      target:
        source:
          pages:
            - "pages/NewIndex"
          sourceRoots:
            - "./src/apple_debug"
        output:
          artifactName: "apple_new_hap"
''');

    final input = '''
{
  "targets": [
    {
      "name": "apple_debug",
      "runtimeOS": "HarmonyOS",
      "output": {
        "artifactName": "legacy_hap",
        "compressLevel": 3
      },
      "resource": {
        "directories": [
          "./src/main/legacy/resources"
        ]
      }
    },
    {
      "name": "legacy",
      "runtimeOS": "HarmonyOS"
    }
  ]
}
''';

    final processor = OhosTargetsProcessor(
      input: input,
      config: config,
      logger: logger,
    );

    final decoded =
        Map<String, dynamic>.from(json5Decode(processor.execute()) as Map);
    final targets = (decoded['targets'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);

    final apple =
        targets.firstWhere((target) => target['name'] == 'apple_debug');
    expect(apple['runtimeOS'], 'HarmonyOS');
    expect(apple.containsKey('source'), isTrue);
    expect(apple.containsKey('resource'), isFalse);
    final output = Map<String, dynamic>.from(apple['output'] as Map);
    expect(output['artifactName'], 'apple_new_hap');
    expect(output['compressLevel'], 3);

    expect(targets.any((target) => target['name'] == 'legacy'), isTrue);
  });

  test('Test OhosTargetsProcessor validates string array fields', () {
    final config = Flavorizr.parse('''
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      target:
        source:
          pages: "pages/Index"
''');

    final processor = OhosTargetsProcessor(config: config, logger: logger);
    expect(
      () => processor.execute(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('target.source.pages'),
        ),
      ),
    );
  });

  test('Test OhosTargetsProcessor is idempotent', () {
    final config = Flavorizr.parse('''
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      name: "apple_debug"
      target:
        source:
          pages:
            - "pages/Index"
          sourceRoots:
            - "./src/apple_debug"
''');

    final processor = OhosTargetsProcessor(config: config, logger: logger);
    final first = processor.execute();

    final secondProcessor = OhosTargetsProcessor(
      input: first,
      config: config,
      logger: logger,
    );
    final second = secondProcessor.execute();

    final firstDecoded = json5Decode(first);
    final secondDecoded = json5Decode(second);
    expect(secondDecoded, firstDecoded);
  });

  test('Test ohos:targets writes into entry build-profile.json5', () async {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_targets_profile_');

    try {
      Directory.current = temp;
      final profileFile = File('${temp.path}/${K.ohosEntryBuildProfilePath}')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "apiType": "stageMode"
}
''');

      final config = Flavorizr.parse('''
instructions:
  - ohos:targets
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      name: "apple_debug"
      target:
        source:
          pages:
            - "pages/Index"
          sourceRoots:
            - "./src/apple_debug"
''');

      Processor(config, force: true, logger: logger).execute();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final decoded = Map<String, dynamic>.from(
        json5Decode(profileFile.readAsStringSync()) as Map,
      );
      final targets = (decoded['targets'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      final target = targets.single;

      expect(target['name'], 'apple_debug');
      expect(
        Directory('${temp.path}/ohos/entry/src/apple_debug').existsSync(),
        isTrue,
      );
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test('Test OhosTargetsTargetFileProcessor is idempotent', () {
    final previousCwd = Directory.current;
    final temp = Directory.systemTemp.createTempSync('flavorizr_ohos_targets_');

    try {
      Directory.current = temp;
      final profileFile = File('${temp.path}/${K.ohosEntryBuildProfilePath}')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "apiType": "stageMode"
}
''');

      final config = Flavorizr.parse('''
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      name: "apple_debug"
''');

      final fileProcessor =
          OhosTargetsTargetFileProcessor(config: config, logger: logger);
      fileProcessor.execute();
      final first = profileFile.readAsStringSync();
      fileProcessor.execute();
      final second = profileFile.readAsStringSync();

      expect(first, second);
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test(
      'Test OhosTargetsTargetFileProcessor does not overwrite existing resources',
      () {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_targets_no_cover_');

    try {
      Directory.current = temp;
      File('${temp.path}/${K.ohosEntryBuildProfilePath}')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "apiType": "stageMode"
}
''');
      File(
          '${temp.path}/ohos/entry/src/main/resources/base/element/string.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('from-main');
      final flavorResourceFile = File(
        '${temp.path}/ohos/entry/src/main/apple_debug/resources/base/element/string.json',
      )
        ..createSync(recursive: true)
        ..writeAsStringSync('custom-existing');

      final config = Flavorizr.parse('''
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      name: "apple_debug"
''');

      OhosTargetsTargetFileProcessor(config: config, logger: logger).execute();

      expect(flavorResourceFile.readAsStringSync(), 'custom-existing');
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });
}
