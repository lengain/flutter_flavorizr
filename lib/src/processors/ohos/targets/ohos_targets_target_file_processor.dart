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

import 'dart:convert' show JsonEncoder;
import 'dart:io' show Directory, File;

import 'package:flutter_flavorizr/src/parser/models/flavorizr.dart';
import 'package:flutter_flavorizr/src/processors/commons/abstract_processor.dart';
import 'package:flutter_flavorizr/src/processors/commons/dynamic_file_string_processor.dart';
import 'package:flutter_flavorizr/src/processors/commons/new_file_string_processor.dart';
import 'package:flutter_flavorizr/src/processors/ohos/targets/ohos_targets_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:json5/json5.dart';
import 'package:mason_logger/mason_logger.dart';

/// Orchestrates the generation and persistence of HarmonyOS entry module's
/// build-profile targets configuration.
///
/// HarmonyOS projects can have their build-profile file at several locations
/// depending on the project structure. This processor auto-detects the existing
/// file path, delegates JSON5 content generation to [OhosTargetsProcessor],
/// then ensures all declared source/resource directories are created on disk.
class OhosTargetsTargetFileProcessor extends AbstractProcessor<void> {
  /// Candidate paths ordered by precedence. The first path found to exist
  /// will be used for reading/writing. Paths under `ohos/entry/` represent the
  /// standard HarmonyOS project structure; paths under `entry/` are fallbacks
  /// for non-standard or older project layouts.
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
    // Select the first existing path, or fall back to the generated path.
    final targetPath = candidatePaths.firstWhere(
      (path) => File(path).existsSync(),
      orElse: () => K.ohosEntryTargetsPath,
    );

    final processor = OhosTargetsProcessor(
      config: config,
      logger: logger,
    );

    if (File(targetPath).existsSync()) {
      // Existing file: read current content, merge generated targets, write back.
      DynamicFileStringProcessor(
        targetPath,
        processor,
        config: config,
        logger: logger,
      ).execute();
    } else {
      // No existing file: generate fresh content and create the file.
      NewFileStringProcessor(
        targetPath,
        processor,
        config: config,
        logger: logger,
      ).execute();
    }

    // After persisting the build-profile, create declared source and resource
    // directories so that hvigor does not fail due to missing paths.
    _prepareResources(targetPath, processor.buildTargets());
  }

  /// Creates directories declared in each target's `source.sourceRoots` and
  /// `resource.directories`, along with the required localization scaffolds.
  ///
  /// The main `./src/main/resources` directory is intentionally skipped to
  /// avoid interfering with the default target's resource configuration.
  void _prepareResources(
    String targetPath,
    List<Map<String, dynamic>> targets,
  ) {
    final entryRootPath = File(targetPath).parent.path;

    for (final target in targets) {
      final name = target['name']?.toString();
      if (name == null || name.isEmpty) {
        continue;
      }

      // Create directories for custom source roots.
      final source = target['source'];
      final sourceRoots = source is Map ? source['sourceRoots'] : null;
      if (sourceRoots is List) {
        for (final sourceRoot in sourceRoots) {
          if (sourceRoot is! String || sourceRoot.isEmpty) {
            continue;
          }
          final sourceDir = Directory(_resolvePath(entryRootPath, sourceRoot));
          if (!sourceDir.existsSync()) {
            sourceDir.createSync(recursive: true);
          }
        }
      }

      // Create directories for custom resource paths and their localization scaffolds.
      final resource = target['resource'];
      final resourceDirectories =
          resource is Map ? resource['directories'] : null;
      if (resourceDirectories is List && resourceDirectories.isNotEmpty) {
        for (final resourceDirectory in resourceDirectories) {
          if (resourceDirectory is! String || resourceDirectory.isEmpty) {
            continue;
          }
          // Skip the default main resources path to preserve the default target.
          if (_isMainResources(resourceDirectory)) {
            continue;
          }
          final targetDirectory =
              Directory(_resolvePath(entryRootPath, resourceDirectory));
          if (!targetDirectory.existsSync()) {
            targetDirectory.createSync(recursive: true);
          }
          final iconPathFromConfig = _extractAbilityIconFromConfig(name);
          _ensureResourceScaffold(
            targetDirectory,
            name,
            target,
            iconPathFromConfig,
          );
        }
      }
    }
  }

  /// Creates the standard HarmonyOS resource localization scaffold under
  /// [directory]:
  ///
  ///   base/element/, base/media/, en_US/element/, zh_CN/element/
  ///
  /// For `base/element/`: if [target] contains an `EntryAbility` with a
  /// `$string:LabelName` label reference, the corresponding entry in the
  /// `string.json` file is created or its missing `value` is filled with [flavorName].
  ///
  /// For `base/media/`: if [iconPathFromConfig] is set (from the original
  /// flavorizr YAML), the icon file is copied and renamed to
  /// `{flavorName}_icon.<ext>`.
  void _ensureResourceScaffold(
    Directory directory,
    String flavorName,
    Map<String, dynamic> target,
    String? iconPathFromConfig,
  ) {
    const requiredPaths = <String>[
      'base/element',
      'base/media',
      'en_US/element',
      'zh_CN/element',
    ];

    final labelName = _extractAbilityLabel(target);
    final iconPath = iconPathFromConfig;

    for (final relativePath in requiredPaths) {
      final subDir = Directory('${directory.path}/$relativePath');
      if (!subDir.existsSync()) {
        subDir.createSync(recursive: true);
      }

      if (relativePath.endsWith('element')) {
        _upsertStringResource(subDir, labelName, flavorName);
      } else if (relativePath.endsWith('media')) {
        _upsertMediaResource(subDir, iconPath, flavorName);
      }
    }
  }

  /// Reads the icon path from the original flavorizr config (before
  /// [OhosTargetsProcessor] rewrites `icon` to `$media:...`).
  String? _extractAbilityIconFromConfig(String flavorName) {
    final flavor = config.ohosFlavors[flavorName];
    if (flavor == null) return null;

    final ohos = flavor.ohos;
    if (ohos == null) return null;

    final target = ohos.target;
    if (target == null) return null;

    List? abilities;

    final source = target['source'];
    if (source is Map) {
      abilities = source['abilities'];
    }

    if (abilities is! List) {
      final resource = target['resource'];
      if (resource is Map) {
        abilities = resource['abilities'];
      }
    }

    if (abilities is! List) return null;

    for (final ability in abilities) {
      if (ability is! Map) continue;
      if (ability['name'] != 'EntryAbility') continue;
      final icon = ability['icon'];
      if (icon is String && icon.isNotEmpty) {
        return icon;
      }
    }
    return null;
  }

  /// Extracts the label name from `label` in [target]'s `abilities` list.
  ///
  /// Searches inside `target['source']` first, then falls back to
  /// `target['resource']`. Accepts `$string:LabelName`, `$string: LabelName`,
  /// and `$string : LabelName` variants. Returns the normalized label name,
  /// or `null` if not found.
  String? _extractAbilityLabel(Map<String, dynamic> target) {
    List? abilities;

    final source = target['source'];
    if (source is Map) {
      abilities = source['abilities'];
    }

    if (abilities is! List) {
      final resource = target['resource'];
      if (resource is Map) {
        abilities = resource['abilities'];
      }
    }

    if (abilities is! List) return null;

    for (final ability in abilities) {
      if (ability is! Map) continue;
      final label = ability['label'];
      if (label is! String) continue;

      final dollarStringIndex = label.indexOf(r'$string');
      if (dollarStringIndex < 0) continue;

      // Strip the '$string' prefix and any characters that follow up to and
      // including the first colon. Handles '$string:', '$string :', etc.
      final afterPrefix = label.substring(dollarStringIndex + r'$string'.length);
      final colonIndex = afterPrefix.indexOf(':');
      if (colonIndex < 0) continue;

      final afterColon = afterPrefix.substring(colonIndex + 1).trim();
      if (afterColon.isEmpty) continue;

      return afterColon;
    }
    return null;
  }

  /// Reads the `string.json` under [elementDir].
  ///
  /// If the file does not exist, returns a new empty structure `{"string": []}`.
  Map<String, dynamic> _readStringJson(File stringJsonFile) {
    if (!stringJsonFile.existsSync()) {
      return {'string': <Map<String, dynamic>>[]};
    }
    final raw = stringJsonFile.readAsStringSync();
    if (raw.trim().isEmpty) {
      return {'string': <Map<String, dynamic>>[]};
    }
    try {
      final decoded = json5Decode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Malformed JSON5: rebuild from scratch.
    }
    return {'string': <Map<String, dynamic>>[]};
  }

  /// Creates or updates the `string.json` file under [elementDir] so that the
  /// entry named [labelName] has its `value` set to [appName].
  ///
  /// If [labelName] is `null`, creates an empty `string.json` with an empty
  /// string array. If an entry with that name already exists but has a
  /// non-empty `value`, the file is left untouched.
  void _upsertStringResource(Directory elementDir, String? labelName, String appName) {
    final stringJsonFile = File('${elementDir.path}/string.json');

    // If no labelName is provided, write an empty string resource file and return.
    if (labelName == null) {
      stringJsonFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'string': []}),
      );
      return;
    }

    final content = _readStringJson(stringJsonFile);
    final stringList = (content['string'] as List).cast<Map<String, dynamic>>();

    final existingIndex = stringList.indexWhere(
      (item) => item['name'] == labelName,
    );

    if (existingIndex >= 0) {
      // Entry exists; only fill in a missing value.
      if (stringList[existingIndex]['value'] == null) {
        stringList[existingIndex]['value'] = appName;
        content['string'] = stringList;
        stringJsonFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(content),
        );
      }
    } else {
      // Entry does not exist; append a new one.
      stringList.add({'name': labelName, 'value': appName});
      content['string'] = stringList;
      stringJsonFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(content),
      );
    }
  }

  /// Copies the icon file from [iconPath] to [mediaDir] and renames it to
  /// `{flavorName}_icon` with the original extension preserved.
  ///
  /// If [iconPath] is `null` or the source file does not exist, nothing is done.
  void _upsertMediaResource(Directory mediaDir, String? iconPath, String flavorName) {
    if (iconPath == null) return;

    // Resolve relative paths against the current working directory (project root).
    final sourceFile = _resolveFile(iconPath);
    if (!sourceFile.existsSync()) return;

    final extension = _extension(iconPath);
    final destFileName = '${flavorName}_icon$extension';
    final destFile = File('${mediaDir.path}/$destFileName');

    if (!destFile.existsSync()) {
      sourceFile.copySync(destFile.path);
    }
  }

  /// Resolves [path] to an absolute path if it is relative, using
  /// [Directory.current] as the base. Absolute paths are returned unchanged.
  File _resolveFile(String path) {
    if (path.startsWith('/')) {
      return File(path);
    }
    final relative = path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^\./'), '');
    return File('${Directory.current.path}/$relative');
  }

  String _extension(String path) {
    final index = path.lastIndexOf('.');
    if (index < 0 || index == path.length - 1) return '';
    return path.substring(index);
  }

  /// Returns true if [path] refers to the default target's main resources
  /// directory (`./src/main/resources` or `src/main/resources`).
  ///
  /// This guard prevents flavorizr from accidentally creating or scaffolding
  /// the main resources directory, which belongs to the default target and
  /// should remain under direct developer control.
  bool _isMainResources(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized == './src/main/resources' ||
        normalized == 'src/main/resources';
  }

  /// Resolves [relativeOrAbsolute] to an absolute path.
  ///
  /// - Absolute paths (starting with `/`) are returned unchanged.
  /// - Relative paths have `./` stripped and are joined with [base].
  /// - Backslashes are normalized to forward slashes for cross-platform compat.
  String _resolvePath(String base, String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('/')) {
      return relativeOrAbsolute;
    }
    final relative = relativeOrAbsolute
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^\./'), '');
    return '$base/$relative';
  }

  @override
  String toString() => 'OhosTargetsTargetFileProcessor';
}
