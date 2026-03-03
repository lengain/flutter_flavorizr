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
import 'package:flutter_flavorizr/src/processors/commons/dynamic_file_string_processor.dart';
import 'package:flutter_flavorizr/src/processors/commons/new_file_string_processor.dart';
import 'package:flutter_flavorizr/src/processors/ohos/config/ohos_config_ast_merge_processor.dart';
import 'package:flutter_flavorizr/src/processors/ohos/config/ohos_config_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:mason_logger/mason_logger.dart';

class OhosConfigTargetFileProcessor extends AbstractProcessor<void> {
  static final candidatePaths = [
    K.ohosBuildProfile5Path,
    K.ohosBuildProfilePath,
    K.appBuildProfile5Path,
    K.appBuildProfilePath,
    K.appScopePath,
    K.entryModulePath,
  ];

  OhosConfigTargetFileProcessor({
    required Flavorizr config,
    required Logger logger,
  }) : super(config, logger: logger);

  @override
  void execute() {
    final targetPath = candidatePaths.firstWhere(
      (path) => File(path).existsSync(),
      orElse: () => K.ohosFlavorizrPath,
    );

    if (File(targetPath).existsSync()) {
      DynamicFileStringProcessor(
        targetPath,
        OhosConfigAstMergeProcessor(
          config: config,
          logger: logger,
        ),
        config: config,
        logger: logger,
      ).execute();
      return;
    }

    NewFileStringProcessor(
      targetPath,
      OhosConfigProcessor(
        config: config,
        logger: logger,
      ),
      config: config,
      logger: logger,
    ).execute();
  }

  @override
  String toString() => 'OhosConfigTargetFileProcessor';
}
