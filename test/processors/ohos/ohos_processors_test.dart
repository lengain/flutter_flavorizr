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
import 'dart:io';

import 'package:flutter_flavorizr/src/parser/models/flavorizr.dart';
import 'package:flutter_flavorizr/src/parser/parser.dart';
import 'package:flutter_flavorizr/src/processors/ohos/config/ohos_config_processor.dart';
import 'package:flutter_flavorizr/src/processors/ohos/icons/ohos_icons_processor.dart';
import 'package:flutter_flavorizr/src/processors/ohos/products/ohos_products_processor.dart';
import 'package:flutter_flavorizr/src/processors/processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
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

  test('Test OhosConfigProcessor', () {
    final processor = OhosConfigProcessor(
      config: flavorizr,
      logger: logger,
    );

    final actual = jsonDecode(processor.execute()) as Map<String, dynamic>;
    final flavors = (actual['flavors'] as List).cast<Map<String, dynamic>>();

    expect(flavors.length, 2);
    expect(
      flavors
          .any((flavor) => flavor['applicationId'] == 'com.example.apple.ohos'),
      isTrue,
    );
  });

  test('Test OhosProductsProcessor', () {
    final processor = OhosProductsProcessor(
      config: flavorizr,
      logger: logger,
    );

    final actual = jsonDecode(processor.execute()) as Map<String, dynamic>;
    final products = (actual['products'] as List).cast<Map<String, dynamic>>();

    expect(products.length, 2);
    expect(products.any((product) => product['name'] == 'apple'), isFalse);
    expect(products.any((product) => product['name'] == 'apple_debug'), isTrue);
    expect(products.any((product) => product['name'] == 'banana'), isTrue);
  });

  test('Test OhosIconsProcessor', () {
    final previousCwd = Directory.current;
    final temp = Directory.systemTemp.createTempSync('flavorizr_ohos_icons_');

    try {
      Directory.current = temp;
      final appleIcon = File('${temp.path}/apple.png')
        ..writeAsStringSync('apple');
      final bananaIcon = File('${temp.path}/banana.webp')
        ..writeAsStringSync('banana');

      final config = Flavorizr.parse('''
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      icon: "${appleIcon.path}"
  banana:
    app:
      name: "Banana App"
    ohos:
      applicationId: "com.example.banana.ohos"
      icon: "${bananaIcon.path}"
''');

      OhosIconsProcessor(
        config: config,
        logger: logger,
      ).execute();

      expect(
        File('${temp.path}/ohos/entry/src/main/resources/base/media/ic_launcher_apple.png')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${temp.path}/ohos/entry/src/main/resources/base/media/ic_launcher_banana.webp')
            .existsSync(),
        isTrue,
      );
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test('Test processor filters OHOS instructions when unavailable', () async {
    final previousCwd = Directory.current;
    final temp = Directory.systemTemp.createTempSync('flavorizr_ohos_filter_');

    try {
      Directory.current = temp;

      final config = Flavorizr.parse('''
instructions:
  - ohos:config
flavors:
  apple:
    app:
      name: "Apple App"
''');

      Processor(
        config,
        force: true,
        logger: logger,
      ).execute();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(File('${temp.path}/ohos/flavorizr.json').existsSync(), isFalse);
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test('Test ohos:products writes into existing build-profile5.json5',
      () async {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_build_profile_');

    try {
      Directory.current = temp;
      final profileFile = File('${temp.path}/${K.ohosBuildProfile5Path}')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "app": {
    "name": "DemoApp"
  }
}
''');
      final config = Flavorizr.parse('''
instructions:
  - ohos:products
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      customConfig:
        productName: "apple_debug"
  banana:
    app:
      name: "Banana App"
    ohos:
      applicationId: "com.example.banana.ohos"
''');

      Processor(
        config,
        force: true,
        logger: logger,
      ).execute();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final content = profileFile.readAsStringSync();
      final decoded = Map<String, dynamic>.from(json5Decode(content) as Map);

      expect(decoded['products'], isNotNull);
      expect(
        File('${temp.path}/${K.ohosProductsPath}').existsSync(),
        isFalse,
      );
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test('Test ohos:products is idempotent on existing build-profile', () async {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_idempotent_');

    try {
      Directory.current = temp;
      final profileFile = File('${temp.path}/${K.ohosBuildProfilePath}')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "app": {
    "name": "DemoApp"
  }
}
''');
      final config = Flavorizr.parse('''
instructions:
  - ohos:products
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      customConfig:
        productName: "apple_debug"
  banana:
    app:
      name: "Banana App"
    ohos:
      applicationId: "com.example.banana.ohos"
''');

      final processor = Processor(
        config,
        force: true,
        logger: logger,
      );

      processor.execute();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final firstRun = profileFile.readAsStringSync();

      processor.execute();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final secondRun = profileFile.readAsStringSync();
      final decoded = Map<String, dynamic>.from(json5Decode(secondRun) as Map);

      expect(firstRun, secondRun);
      expect(
        (decoded['products'] as List).isNotEmpty,
        isTrue,
      );
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test('Test ohos:config auto injects into AppScope app.json5', () async {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_config_appscope_');

    try {
      Directory.current = temp;
      final appScopeFile = File('${temp.path}/${K.appScopePath}')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  app: {
    bundleName: "com.example.demo",
  },
}
''');

      final config = Flavorizr.parse('''
instructions:
  - ohos:config
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
''');

      Processor(
        config,
        force: true,
        logger: logger,
      ).execute();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final content = appScopeFile.readAsStringSync();
      expect(content.contains('ohosConfig'), isTrue);
      expect(content.contains('schemaVersion'), isTrue);
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test('Test ohos:config is idempotent on entry module json5', () async {
    final previousCwd = Directory.current;
    final temp =
        Directory.systemTemp.createTempSync('flavorizr_ohos_config_module_');

    try {
      Directory.current = temp;
      final moduleFile = File('${temp.path}/${K.entryModulePath}')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  module: {
    name: "entry",
  },
}
''');

      final config = Flavorizr.parse('''
instructions:
  - ohos:config
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
''');

      final processor = Processor(
        config,
        force: true,
        logger: logger,
      );

      processor.execute();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final firstRun = moduleFile.readAsStringSync();

      processor.execute();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final secondRun = moduleFile.readAsStringSync();

      expect(firstRun, secondRun);
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });

  test(
      'Test ohos:products auto invokes ohos:config when missing in instructions',
      () async {
    final previousCwd = Directory.current;
    final temp = Directory.systemTemp
        .createTempSync('flavorizr_ohos_products_auto_config_');

    try {
      Directory.current = temp;

      final config = Flavorizr.parse('''
instructions:
  - ohos:products
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      applicationId: "com.example.apple.ohos"
      customConfig:
        productName: "apple_debug"
''');

      Processor(
        config,
        force: true,
        logger: logger,
      ).execute();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final generatedProducts =
          File('${temp.path}/${K.ohosProductsPath}').existsSync();
      final generatedConfig =
          File('${temp.path}/${K.ohosFlavorizrPath}').existsSync();

      expect(generatedProducts, isTrue);
      expect(generatedConfig, isTrue);
    } finally {
      Directory.current = previousCwd;
      temp.deleteSync(recursive: true);
    }
  });
}
