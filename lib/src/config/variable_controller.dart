import 'package:mustache_template/mustache.dart' show Template;
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

enum _ResolveMethod {
  original('original'),
  pascalCase('pascalCase'),
  camelCase('camelCase'),
  snakeCase('snakeCase'),
  paramCase('paramCase'),
  dotCase('dotCase'),
  pathCase('pathCase'),
  sentenceCase('sentenceCase'),
  titleCase('titleCase'),
  constantCase('constantCase'),
  headerCase('headerCase'),
  fileNameWithoutExt('fileNameWithoutExt');

  final String method;
  const _ResolveMethod(this.method);

  factory _ResolveMethod.fromMethod(String method) {
    return values.firstWhere(
      (e) => e.method == method,
      orElse: () => _ResolveMethod.original,
    );
  }
}

/// A controller responsible for managing and resolving variables within strings
/// using Mustache templates.
final class VariableController {
  /// Internal storage for key-value pairs used during template resolution.
  final Map<String, Object> _storage = {};

  /// Resolves placeholders in the provided [template] string using the current storage.
  ///
  /// The [template] follows the Mustache syntax. Values are HTML-escaped by default.
  ///
  /// Example:
  /// ```dart
  /// controller.inject(key: 'name', value: 'World');
  /// final result = controller.resolve('Hello, {{name}}!'); // 'Hello, World!'
  /// ```
  String resolve(String template) {
    final pattern = RegExp(r'\{\{\s*(\w+)\.(\w+)\(\)\s*\}\}');

    final processed = template.replaceAllMapped(pattern, (match) {
      final key = match.group(1)!;
      final method = match.group(2)!;

      final value = _storage[key];
      if (value == null) return match.group(0)!;

      return _resolveMethod(value as String, _ResolveMethod.fromMethod(method));
    });

    final t = Template(processed, htmlEscapeValues: false);
    return t.renderString(_storage);
  }

  String _resolveMethod(String value, _ResolveMethod method) {
    final rc = ReCase(value);
    return switch (method) {
      _ResolveMethod.original => value,
      _ResolveMethod.pascalCase => rc.pascalCase,
      _ResolveMethod.camelCase => rc.camelCase,
      _ResolveMethod.snakeCase => rc.snakeCase,
      _ResolveMethod.paramCase => rc.paramCase,
      _ResolveMethod.dotCase => rc.dotCase,
      _ResolveMethod.pathCase => rc.pathCase,
      _ResolveMethod.sentenceCase => rc.sentenceCase,
      _ResolveMethod.titleCase => rc.titleCase,
      _ResolveMethod.constantCase => rc.constantCase,
      _ResolveMethod.headerCase => rc.headerCase,
      _ResolveMethod.fileNameWithoutExt => p.basenameWithoutExtension(value),
    };
  }

  /// Injects a new [key]-[value] pair into the controller's storage.
  ///
  /// If the [key] already exists, its value will be overwritten.
  ///
  /// Example:
  /// ```dart
  /// controller.inject(key: 'version', value: '1.0.0');
  /// ```
  void inject({required String key, required Object value}) {
    _storage[key] = value;
  }

  /// Returns a copy of the current variables stored in the controller.
  ///
  /// Example:
  /// ```dart
  /// final currentVars = controller.values;
  /// ```
  Map<String, String> get values => Map.from(_storage);
}
