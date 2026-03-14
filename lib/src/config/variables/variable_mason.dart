part of 'variables.dart';

/// {@template mason_variable}
/// A variable that resolves its value by prompting the user in the console,
/// mimicking the behavior of the [Mason](https://pub.dev/packages/mason) CLI.
///
/// It supports optional regex validation via [pattern].
/// {@endtemplate}
final class MasonVariable extends Variable {
  /// The message displayed to the user when prompting for input.
  /// This string can contain placeholders that will be resolved via [resolveTemplate].
  final String prompt;

  /// An optional regular expression pattern used to validate the user's input.
  final String? pattern;

  /// {@macro mason_variable}
  MasonVariable({
    required super.name,
    required this.prompt,
    super.description,
    super.variableType,
    this.pattern,
  }) : super(behavior: .mason);

  /// Creates a [MasonVariable] instance from a [Json] map.
  ///
  /// Throws a [ConfigException] if required fields like `name` or `prompt` are missing
  /// or have an invalid type.
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "name": "project_name",
  ///   "prompt": "Enter the name of your project",
  ///   "pattern": "^[a-z_]+$"
  /// }
  /// ```
  static MasonVariable import(Json json) {
    final name = ConfigEntity.castFieldTo<String>(
      field: 'name',
      value: json['name'],
      entityType: .variable,
    );

    final prompt = ConfigEntity.castFieldTo<String>(
      field: 'prompt',
      value: json['prompt'],
      entityType: .variable,
    );

    final description = json['description'] as String?;
    final pattern = json['pattern'] as String?;

    return MasonVariable(
      name: name,
      prompt: prompt,
      description: description,
      pattern: pattern,
    );
  }

  /// Displays the [prompt] to the user and waits for input.
  ///
  /// If [pattern] is provided, the input is validated against it.
  /// Returns [ResolveResult.retry] if validation fails, otherwise [ResolveResult.ok].
  @override
  Future<ResolveResult> resolve(Logger logger) async {
    final value = logger.prompt(resolveTemplate(prompt)).trim();

    if (pattern != null && !RegExp(pattern!).hasMatch(value)) {
      logger.warn('Value "$value" does not match pattern "$pattern"');
      return .retry;
    }

    inject(value);
    return .ok;
  }
}
