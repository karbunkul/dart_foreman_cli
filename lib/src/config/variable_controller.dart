import 'package:mustache_template/mustache.dart' show Template;

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
    final t = Template(template, htmlEscapeValues: true);

    return t.renderString(_storage);
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
