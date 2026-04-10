import 'package:mustache_template/mustache.dart' show Template;
import 'package:recase/recase.dart';

enum _ResolveMethod {
  original('original'),
  pascalCase('pascalCase');

  final String method;
  const _ResolveMethod(this.method);

  factory _ResolveMethod.fromMethod(String method) {
    return values.firstWhere(
      (e) => e.method == method,
      orElse: () => .original,
    );
  }
}

/// A controller responsible for managing and resolving variables within strings
/// using Mustache templates.
final class VariableController {
  /// Internal storage for key-value pairs used during template resolution.
  final Map<String, String> _storage = {};

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
    final pattern = RegExp(r'{{\s?(\w+)\.(\w+)\(\)\s?}}');

    if (pattern.hasMatch(template)) {
      print('ku');
      final withPlaceHolders = template.replaceAllMapped(pattern, (match) {
        if (match.groupCount == 2) {
          final key = match.group(1)!;
          final method = match.group(2)!;
          final value = _storage[key]!;

          return _resolveMethod(value, _ResolveMethod.fromMethod(method));
        }

        throw UnimplementedError();
      });
      final t = Template(withPlaceHolders, htmlEscapeValues: true);

      return t.renderString(_storage);
    } else {
      final t = Template(template, htmlEscapeValues: true);
      return t.renderString(_storage);
    }
  }

  String _resolveMethod(String value, _ResolveMethod method) {
    return switch (method) {
      _ResolveMethod.original => value,
      _ResolveMethod.pascalCase => ReCase(value).pascalCase,
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
  void inject({required String key, required String value}) {
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
