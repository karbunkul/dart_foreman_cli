part of 'config.dart';

/// Represents the top-level specification of the configuration.
///
/// This class holds a collection of [BlueprintSpec] objects and provides
/// methods to access them by name or iterate through the entire set.
final class ConfigSpec {
  /// Internal storage for blueprints, mapped by their unique names.
  late final Map<String, BlueprintSpec> _blueprints;

  /// Creates a [ConfigSpec] from a list of [BlueprintSpec] instances.
  ///
  /// The blueprints are stored in an unmodifiable map for thread-safety
  /// and data integrity.
  ConfigSpec({required List<BlueprintSpec> blueprints})
    : _blueprints = Map.unmodifiable({for (final b in blueprints) b.name: b});

  /// Retrieves a [BlueprintSpec] by its [name].
  ///
  /// Returns `null` if no blueprint with the given name exists.
  ///
  /// Example:
  /// ```dart
  /// final spec = config['repository'];
  /// ```
  BlueprintSpec? operator [](String name) => _blueprints[name];

  /// Checks if a blueprint with the given [name] exists in the configuration.
  ///
  /// Returns `true` if found, `false` otherwise.
  bool has(String name) => _blueprints.containsKey(name);

  /// Returns an iterable of all blueprint names (keys) available in the config.
  Iterable<String> get allKeys => _blueprints.keys;

  /// Returns an iterable of all [BlueprintSpec] instances stored in the config.
  Iterable<BlueprintSpec> get all => _blueprints.values;

  /// Creates a [ConfigSpec] instance by parsing a [Json] object.
  ///
  /// This method extracts the `blueprints` map from the JSON, validates
  /// the structure using [ConfigEntity.castFieldTo], and initializes
  /// individual [BlueprintSpec] objects.
  ///
  /// Example JSON structure:
  /// ```json
  /// {
  ///   "blueprints": {
  ///     "service": { "path": "lib/services" },
  ///     "model": { "path": "lib/models" }
  ///   }
  /// }
  /// ```
  static ConfigSpec import(Json json) {
    final blueprints = <BlueprintSpec>[];

    // Safely cast the 'blueprints' field to a Map
    final blueprintsRaw = ConfigEntity.castFieldTo<Map>(
      field: 'blueprints',
      value: json['blueprints'],
      entityType: .config,
      defaultValue: {},
    );

    for (final entry in blueprintsRaw.entries) {
      // Validate each entry in the blueprints map
      final newEntry = ConfigEntity.castFieldTo<Map>(
        field: 'entry',
        value: entry.value,
        entityType: .config,
        defaultValue: {},
      );

      // Import the blueprint using the key as the name
      final blueprint = BlueprintSpec.import({'name': entry.key, ...newEntry});
      blueprints.add(blueprint);
    }

    return ConfigSpec(blueprints: blueprints);
  }
}
