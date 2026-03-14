part of 'config.dart';

/// Defines the interaction behavior for a variable during the brick generation process.
///
/// It determines how the CLI prompts the user or processes the value.
enum VariableBehavior {
  /// Standard behavior where Mason handles the input via standard prompts.
  ///
  /// Example:
  /// ```yaml
  /// vars:
  ///   project_name:
  ///     type: string
  ///     behavior: mason
  /// ```
  mason(
    id: 'mason',
    allowTo: [.string, .boolean, .number, .array, .enumeration, .list],
  ),

  /// Executes a shell command to determine the variable value or provide suggestions.
  ///
  /// Example:
  /// ```yaml
  /// vars:
  ///   branch_name:
  ///     type: string
  ///     behavior: shell
  ///     command: git rev-parse --abbrev-ref HEAD
  /// ```
  shell(
    id: 'shell',
    allowTo: [.string, .boolean, .number, .array, .enumeration, .list],
  ),

  /// Combines multiple existing variables into a single value.
  ///
  /// Example:
  /// ```yaml
  /// vars:
  ///   full_path:
  ///     type: string
  ///     behavior: combine
  ///     template: "{{root}}/{{folder}}/{{name}}"
  /// ```
  combine(id: 'combine', allowTo: [.string]),

  /// Opens an interactive directory picker to select a path on the file system.
  ///
  /// Example:
  /// ```yaml
  /// vars:
  ///   output_dir:
  ///     type: string
  ///     behavior: select_directory
  /// ```
  selectDirectory(id: 'select_directory', allowTo: [.string]);

  /// The unique string identifier used in configuration files (e.g., yaml).
  final String id;

  /// The list of [BrickVariableType]s that are compatible with this behavior.
  final List<BrickVariableType> allowTo;

  const VariableBehavior({required this.id, required this.allowTo});

  /// Maps a string [id] to its corresponding [VariableBehavior].
  ///
  /// Returns [VariableBehavior.mason] as the default if [value] is null or unrecognized.
  static VariableBehavior fromId(String? value) {
    return VariableBehavior.values.firstWhere(
      (b) => b.id == value,
      orElse: () => VariableBehavior.mason,
    );
  }
}
