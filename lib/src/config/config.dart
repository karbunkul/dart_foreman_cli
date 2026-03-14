import 'package:foreman_cli/src/config/brick_spec.dart';
import 'package:foreman_cli/src/config/variables/variables.dart';

import 'package:foreman_cli/foreman_cli.dart';
import 'package:foreman_cli/src/config/variable_controller.dart';
import 'package:mason/mason.dart' show BrickVariableType, Logger;
import 'package:meta/meta.dart';

part 'blueprint_spec.dart';
part 'variable.dart';
part 'config_spec.dart';
part 'variable_behavior.dart';

/// A type alias for a standard JSON-compatible map.
typedef Json = Map<String, dynamic>;

/// {@template config_entity}
/// A base utility class for handling configuration entities and performing
/// type-safe casting of dynamic fields.
/// {@endtemplate}
@internal
final class ConfigEntity {
  /// Casts a dynamic [value] to the specified type [R].
  ///
  /// Throws an [EntityCastException] if the casting fails, providing context
  /// about which [field] and [entityType] caused the error.
  ///
  /// ### Example:
  /// ```dart
  /// final name = ConfigEntity.castFieldTo<String>(
  ///   field: 'name',
  ///   value: json['name'],
  ///   entityType: ConfigEntityType.blueprint,
  ///   defaultValue: 'unnamed',
  /// );
  /// ```
  static R castFieldTo<R>({
    required String field,
    required dynamic value,
    required ConfigEntityType entityType,
    Object? defaultValue,
  }) {
    try {
      return (value ?? defaultValue) as R;
    } on Object {
      throw EntityCastException(type: entityType, field: field);
    }
  }
}

/// Defines the types of entities available within the configuration system.
/// Used primarily for error reporting and identification.
@internal
enum ConfigEntityType {
  /// Represents the root configuration object.
  config('config'),

  /// Represents a blueprint definition.
  blueprint('blueprint'),

  /// Represents a variable within a blueprint or brick.
  variable('variable'),

  /// Represents a brick specification.
  brick('brick');

  /// The unique identifier for the entity type.
  final String id;

  const ConfigEntityType(this.id);
}
