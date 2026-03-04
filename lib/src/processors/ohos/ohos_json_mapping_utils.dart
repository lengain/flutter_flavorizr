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

class OhosJsonMappingUtils {
  static Map<String, dynamic> copyAdditionalFields(
    Map<String, dynamic> source, {
    Set<String> excludedKeys = const {},
  }) {
    final additional = <String, dynamic>{};
    for (final entry in source.entries) {
      if (excludedKeys.contains(entry.key)) {
        continue;
      }
      additional[entry.key] = deepClone(entry.value);
    }
    return additional;
  }

  static dynamic deepClone(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key, deepClone(val)));
    }
    if (value is List) {
      return value.map(deepClone).toList(growable: false);
    }
    return value;
  }

  static dynamic mergeNode(dynamic existing, dynamic incoming) {
    if (existing is Map && incoming is Map) {
      final merged = Map<String, dynamic>.from(existing);
      for (final entry in incoming.entries) {
        final key = entry.key.toString();
        merged[key] = mergeNode(merged[key], entry.value);
      }
      return merged;
    }
    return deepClone(incoming);
  }
}
