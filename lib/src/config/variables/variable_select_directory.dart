part of 'variables.dart';

/// A variable implementation that allows the user to select a subdirectory
/// from a specified parent [path].
///
/// This variable scans the directory at [path], lists all immediate
/// subdirectories, and prompts the user to choose one via the CLI.
///
/// ### Example configuration:
/// ```yaml
/// variables:
///   - name: target_module
///     behavior: selectDirectory
///     path: "lib/modules"
///     prompt: "Select the module to update"
///     description: "The module where the new files will be generated"
/// ```
final class SelectDirectoryVariable extends Variable {
  /// The parent directory path to scan for subdirectories.
  /// Supports template resolution (e.g., using other variables in the path).
  final String path;

  /// The message displayed to the user when prompting for selection.
  final String? prompt;

  /// Creates a [SelectDirectoryVariable].
  SelectDirectoryVariable({
    required super.name,
    required this.path,
    this.prompt,
    super.description,
  }) : super(behavior: .selectDirectory, variableType: .string);

  /// Retrieves a sorted list of names of the subdirectories found in [path].
  ///
  /// It normalizes the path and resolves any templates before listing.
  /// Only directories are included; files and links are ignored.
  List<String> get values {
    final workDir = Directory(p.normalize(resolveTemplate(path)));

    final res = workDir
        .listSync(recursive: false, followLinks: false)
        .whereType<Directory>()
        .map((e) => p.basename(e.path))
        .toList(growable: false);

    res.sort();

    return res;
  }

  /// Creates an instance of [SelectDirectoryVariable] from a [Json] map.
  ///
  /// Validates required fields like `name` and `path` using [ConfigEntity.castFieldTo].
  static SelectDirectoryVariable import(Json json) {
    final name = ConfigEntity.castFieldTo<String>(
      field: 'name',
      value: json['name'],
      entityType: .variable,
    );

    final path = ConfigEntity.castFieldTo<String>(
      field: 'path',
      value: json['path'],
      entityType: .variable,
    );

    final prompt = json['prompt'] as String?;
    final description = json['description'] as String?;

    return SelectDirectoryVariable(
      name: name,
      prompt: prompt ?? 'Select a directory from list',
      path: path,
      description: description,
    );
  }

  /// Executes the resolution logic for this variable.
  ///
  /// Displays a selection menu in the terminal. Once a directory is selected,
  /// the value is injected into the global context.
  ///
  /// Returns [ResolveResult.ok] on success or [ResolveResult.cancel] if an error occurs.
  @override
  Future<ResolveResult> resolve(Logger logger) async {
    try {
      final dirs = values;
      if (dirs.isEmpty) {
        throw Exception('No subdirectories found in: $path');
      }

      final value = prompts.choose(
        prompt ?? 'Select directory',
        dirs,
        interactive: false,
      );

      inject(value!);
      return .ok;
    } catch (e) {
      logger.err(e.toString());
      return .cancel;
    }
  }
}
