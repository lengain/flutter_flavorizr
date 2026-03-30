/*
 * Copyright (c) 2024 Angelo Cassano
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
import 'package:mason_logger/mason_logger.dart';

class ShellProcessor extends AbstractProcessor<void> {
  final String _path;
  final String? _workingDirectory;
  final List<String> _args;

  const ShellProcessor(
    this._path,
    this._args, {
    String? workingDirectory,
    required Flavorizr config,
    required Logger logger,
  })  : _workingDirectory = workingDirectory,
        super(config, logger: logger);

  static bool _isRubyExecutable(String path) {
    final normalized = path.replaceAll('\\', '/');
    final baseName = normalized.split('/').last;
    return baseName == 'ruby' || baseName == 'ruby.exe';
  }

  static String _normalizePbxprojShellScript(String input) {
    // Newer Xcode versions may serialize `shellScript` as an Array with a single
    // string element:
    //
    //   shellScript = (
    //     "/bin/sh \"...\" build",
    //   );
    //
    // xcodeproj expects `shellScript` to be a String, causing runtime errors
    // when opening the project. Convert single-element arrays to strings.
    final re = RegExp(
      r'shellScript\s*=\s*\(\s*"((?:\\.|[^"])*)",\s*\);',
      multiLine: true,
    );
    return input.replaceAllMapped(re, (m) => 'shellScript = "${m[1]}";');
  }

  static void _maybeNormalizeXcodeprojForRubyScripts(List<String> args) {
    // ruby <script.rb> <project.xcodeproj> ...
    if (args.length < 2) return;
    final script = args[0];
    final project = args[1];
    if (!script.endsWith('.rb')) return;
    if (!project.endsWith('.xcodeproj')) return;

    final pbxprojPath = '$project/project.pbxproj';
    final pbxprojFile = File(pbxprojPath);
    if (!pbxprojFile.existsSync()) return;

    final original = pbxprojFile.readAsStringSync();
    if (!original.contains('shellScript = (')) return;
    final normalized = _normalizePbxprojShellScript(original);
    if (identical(original, normalized) || original == normalized) return;
    pbxprojFile.writeAsStringSync(normalized);
  }

  @override
  void execute() {
    logger.detail(
      '[$ShellProcessor] Executing shell script path `$_path`'
      ' with arguments `${_args.join(', ')}` in working directory `$_workingDirectory`',
    );

    // xcodeproj (and other Ruby gems) can emit extremely noisy warnings on some
    // Ruby installations (e.g. RVM). They don't affect execution, but they
    // pollute flavorizr logs. Suppress Ruby warnings for Ruby script execution.
    final effectiveArgs = _isRubyExecutable(_path) ? ['-W0', ..._args] : _args;
    if (_isRubyExecutable(_path)) {
      _maybeNormalizeXcodeprojForRubyScripts(_args);
    }

    final result = Process.runSync(
      _path,
      effectiveArgs,
      workingDirectory: _workingDirectory,
    );
    if (result.exitCode != 0) {
      logger.detail(
        '[$ShellProcessor] Error executing shell script path `$_path`'
        ' with arguments `${_args.join(', ')}` in working directory `$_workingDirectory`',
        style: logger.theme.warn,
      );
      logger.warn(result.stderr);
    } else {
      logger.detail(
        '[$ShellProcessor] Shell script path `$_path`'
        ' with arguments `${_args.join(', ')}` in working directory `$_workingDirectory` executed successfully',
        style: logger.theme.success,
      );
    }
  }

  @override
  String toString() =>
      'ShellProcessor: Running script \'$_path\' with arguments ${_args.join(', ')}';
}
