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

import 'package:flutter_flavorizr/src/processors/commons/copy_file_processor.dart';
import 'package:flutter_flavorizr/src/processors/commons/new_folder_processor.dart';
import 'package:flutter_flavorizr/src/processors/commons/queue_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';

class OhosIconsProcessor extends QueueProcessor {
  OhosIconsProcessor({
    required super.config,
    required super.logger,
  }) : super(
          [
            NewFolderProcessor(
              K.ohosMediaPath,
              config: config,
              logger: logger,
            ),
            ...config.ohosFlavors.entries
                .where((entry) => entry.value.ohos?.icon != null)
                .expand(
                  (entry) => [
                    CopyFileProcessor(
                      entry.value.ohos!.icon!,
                      '${K.ohosMediaPath}/ic_launcher_${entry.key}${_extension(entry.value.ohos!.icon!)}',
                      config: config,
                      logger: logger,
                    ),
                  ],
                ),
          ],
        );

  static String _extension(String path) {
    final index = path.lastIndexOf('.');
    if (index < 0 || index == path.length - 1) {
      return '';
    }
    return path.substring(index);
  }

  @override
  String toString() => 'OhosIconsProcessor';
}
