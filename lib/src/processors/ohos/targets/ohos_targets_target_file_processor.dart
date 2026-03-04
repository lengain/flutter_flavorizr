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
import 'package:flutter_flavorizr/src/processors/ohos/targets/ohos_targets_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:mason_logger/mason_logger.dart';

class OhosTargetsTargetFileProcessor extends AbstractProcessor<void> {
  static final candidatePaths = [
    K.ohosEntryBuildProfile5Path,
    K.ohosEntryBuildProfilePath,
    K.appEntryBuildProfile5Path,
    K.appEntryBuildProfilePath,
  ];

  OhosTargetsTargetFileProcessor({
    required Flavorizr config,
    required Logger logger,
  }) : super(config, logger: logger);

  @override
  void execute() {
    final targetPath = candidatePaths.firstWhere(
      (path) => File(path).existsSync(),
      orElse: () => K.ohosEntryTargetsPath,
    );

    final processor = OhosTargetsProcessor(
      config: config,
      logger: logger,
    );

    if (File(targetPath).existsSync()) {
      DynamicFileStringProcessor(
        targetPath,
        processor,
        config: config,
        logger: logger,
      ).execute();
    } else {
      NewFileStringProcessor(
        targetPath,
        processor,
        config: config,
        logger: logger,
      ).execute();
    }

    _prepareResources(targetPath, processor.buildTargets());
  }

  void _prepareResources(
    String targetPath,
    List<Map<String, dynamic>> targets,
  ) {
    final entryRootPath = File(targetPath).parent.path;
    final mainResourcesPath =
        _resolvePath(entryRootPath, './src/main/resources');
    final mainResourcesDir = Directory(mainResourcesPath);

    for (final target in targets) {
      final name = target['name']?.toString();
      if (name == null || name.isEmpty) {
        continue;
      }

      final source = target['source'];
      final sourceRoots = source is Map ? source['sourceRoots'] : null;
      if (sourceRoots is List) {
        for (final sourceRoot in sourceRoots) {
          if (sourceRoot is! String || sourceRoot.isEmpty) {
            continue;
          }
          Directory(_resolvePath(entryRootPath, sourceRoot))
              .createSync(recursive: true);
        }
      }

      final resource = target['resource'];
      final resourceDirectories =
          resource is Map ? resource['directories'] : null;
      if (resourceDirectories is List && resourceDirectories.isNotEmpty) {
        for (final resourceDirectory in resourceDirectories) {
          if (resourceDirectory is! String || resourceDirectory.isEmpty) {
            continue;
          }
          final targetDirectory = Directory(
            _resolvePath(entryRootPath, resourceDirectory),
          );
          targetDirectory.createSync(recursive: true);
          if (_isMainResources(resourceDirectory)) {
            continue;
          }
          if (mainResourcesDir.existsSync()) {
            _copyDirectoryContent(mainResourcesDir, targetDirectory);
          }
        }
      } else {
        final flavorResourcesDir = Directory(
          _resolvePath(entryRootPath, './src/main/$name/resources'),
        )..createSync(recursive: true);
        mainResourcesDir.createSync(recursive: true);
        if (mainResourcesDir.existsSync()) {
          _copyDirectoryContent(mainResourcesDir, flavorResourcesDir);
        }
      }
    }
  }

  void _copyDirectoryContent(Directory source, Directory destination) {
    for (final entity in source.listSync(recursive: false)) {
      if (entity is File) {
        final targetFile =
            File('${destination.path}/${_basename(entity.path)}');
        if (targetFile.existsSync()) {
          continue;
        }
        targetFile.createSync(recursive: true);
        entity.copySync(targetFile.path);
      } else if (entity is Directory) {
        final targetDir = Directory(
          '${destination.path}/${_basename(entity.path)}',
        )..createSync(recursive: true);
        _copyDirectoryContent(entity, targetDir);
      }
    }
  }

  bool _isMainResources(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized == './src/main/resources' ||
        normalized == 'src/main/resources';
  }

  String _resolvePath(String base, String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('/')) {
      return relativeOrAbsolute;
    }
    final relative = relativeOrAbsolute
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^\./'), '');
    return '$base/$relative';
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  @override
  String toString() => 'OhosTargetsTargetFileProcessor';
}
