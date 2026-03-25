part of 'config.dart';

/// Represents a blueprint configuration which defines a set of global variables
/// and a collection of bricks.
///
/// A blueprint acts as a template for generating code or files by combining
/// shared variables with specific brick logic.
final class BlueprintSpec {
  /// The unique name of the blueprint.
  final String name;

  /// A list of global variables shared across all bricks in this blueprint.
  final List<Variable> variables;

  /// A list of bricks associated with this blueprint.
  final List<BrickSpec> bricks;

  /// Creates a [BlueprintSpec] instance.
  const BlueprintSpec({
    required this.name,
    required this.variables,
    required this.bricks,
  });

  /// Validates the blueprint for naming conflicts.
  ///
  /// Throws [DuplicateVariableException] if:
  /// * Multiple global variables share the same name.
  /// * A brick variable shadows a global variable or another variable within the same brick.
  void validate() {
    final Set<String> globalVarSet = {};

    // check global variables
    for (final variable in variables) {
      if (globalVarSet.contains(variable.name)) {
        throw DuplicateVariableException(variable.name);
      } else {
        globalVarSet.add(variable.name);
      }
    }

    // check brick variables
    for (final brick in bricks) {
      final Set<String> brickVarSet = Set.from(globalVarSet);
      for (final variable in brick.variables) {
        if (brickVarSet.contains(variable.name)) {
          throw DuplicateVariableException(
            variable.name,
            brickName: brick.name,
          );
        } else {
          brickVarSet.add(variable.name);
        }
      }
    }
  }

  /// Resolves all variables required for a specific brick.
  ///
  /// This includes global blueprint variables followed by brick-specific variables.
  /// Values are processed sequentially through the [controller].
  ///
  /// Returns a map of variable names and their resolved string values.
  Future<Map<String, String>> resolveBrickVariables({
    required String brickName,
    required Logger logger,
    required VariableController controller,
  }) async {
    final brick = bricks.firstWhere((b) => b.name == brickName);
    final vars = [...variables, ...brick.variables];

    for (final variable in vars) {
      variable.attach(controller);
      if (variable.description != null && variable is! ShellVariable) {
        logger.write('\n ✍️ ${controller.resolve(variable.description!)} \n');
      }
      var result = ResolveResult.retry;
      while (result == .retry) {
        result = await variable.resolve(logger);
      }

      logger.write(' ');

      if (result == .cancel) {
        logger.err('Blueprint is canceled');
        break;
      }
      logger.detail(
        '[${variable.behavior.id}]: 👌 Resolved ${variable.name} = ${controller.values[variable.name]}',
      );

      variable.detach();
    }

    return controller.values;
  }

  /// Creates a [BlueprintSpec] instance from a [Json] map.
  ///
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "name": "my_blueprint",
  ///   "vars": { "app_name": { ... } },
  ///   "bricks": { "ui_kit": { ... } }
  /// }
  /// ```
  static BlueprintSpec import(Json json) {
    final name = ConfigEntity.castFieldTo<String>(
      field: 'name',
      value: json['name'],
      entityType: .blueprint,
    );

    final varsRaw = json['vars'] ?? {};
    final variables = <Variable>[];

    for (final entry in varsRaw.entries) {
      final variable = Variable.import({'name': entry.key, ...entry.value});
      variables.add(variable);
    }

    final bricksRaw = json['bricks'] ?? {};
    final bricks = <BrickSpec>[];

    for (final entry in bricksRaw.entries) {
      final brick = BrickSpec.import({'name': entry.key, ...entry.value});
      bricks.add(brick);
    }

    return BlueprintSpec(name: name, variables: variables, bricks: bricks);
  }
}
