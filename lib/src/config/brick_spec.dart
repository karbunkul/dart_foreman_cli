import 'package:foreman_cli/src/config/config.dart';

/// Represents the specification of a Mason brick as defined in the configuration.
///
/// This class encapsulates the identity, location, and required variables
/// of a brick used for code generation.
final class BrickSpec {
  /// The unique name of the brick (e.g., 'feature_core').
  final String name;

  /// An optional local path or remote URL to the brick's source.
  ///
  /// If null, the brick is expected to be available in the default registry.
  final String? path;

  /// A list of [Variable] definitions required by this brick.
  final List<Variable> variables;

  /// Creates a new [BrickSpec] instance.
  BrickSpec({required this.name, required this.variables, this.path});

  /// Factory method to create a [BrickSpec] from a JSON map.
  ///
  /// The [json] structure should typically contain:
  /// - `name`: String (Required)
  /// - `vars`: Map of variable definitions (Optional)
  /// - `path`: String (Optional)
  ///
  /// Example:
  /// ```dart
  /// final spec = BrickSpec.import({
  ///   'name': 'api_service',
  ///   'path': './bricks/api',
  ///   'vars': {
  ///     'base_url': { 'type': 'string' }
  ///   }
  /// });
  /// ```
  static BrickSpec import(Json json) {
    final name = ConfigEntity.castFieldTo<String>(
      field: 'name',
      value: json['name'],
      entityType: .brick,
    );

    final varsRaw = json['vars'] ?? {};
    final variables = <Variable>[];

    for (final entry in varsRaw.entries) {
      final variable = Variable.import({'name': entry.key, ...entry.value});
      variables.add(variable);
    }

    final path = json['path'] as String?;

    return BrickSpec(name: name, variables: variables, path: path);
  }

  @override
  String toString() {
    return '$runtimeType(name: $name, path: $path, variables: $variables)';
  }
}
