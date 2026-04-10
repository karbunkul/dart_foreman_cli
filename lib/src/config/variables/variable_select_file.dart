part of 'variables.dart';

/// A variable that allows the user to select a file from a list of files found
/// by a glob pattern.
final class SelectFileVariable extends Variable {
  /// The relative directory path to search within.
  final String path;

  /// The glob pattern or filter (e.g., '**/*.dart').
  final String filter;

  /// The prompt message displayed to the user.
  final String prompt;

  SelectFileVariable({
    required super.name,
    required this.path,
    required this.filter,
    required this.prompt,
    super.description,
  }) : super(behavior: .selectFile);

  @override
  Future<ResolveResult> resolve(Logger logger) async {
    try {
      final root = Directory.current.path;
      final searchDir = p.canonicalize(p.join(root, resolveTemplate(path)));

      if (!Directory(searchDir).existsSync()) {
        logger.err('Search directory not found: $searchDir');
        return ResolveResult.cancel;
      }

      final glob = Glob(filter);
      final files = glob
          .listSync(root: searchDir)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: searchDir))
          .toList();

      if (files.isEmpty) {
        logger.warn('No files found matching "$filter" in $searchDir');
      }

      final value = prompts.choose(prompt, files);

      if (value == null) {
        return ResolveResult.cancel;
      }

      inject(value);
      return ResolveResult.ok;
    } catch (e) {
      logger.err('Error during file selection: $e');
      return ResolveResult.cancel;
    }
  }

  static SelectFileVariable import(Json json) {
    return SelectFileVariable(
      name: json['name'],
      path: json['path'] ?? '.',
      filter: json['filter'] ?? '*',
      prompt: json['prompt'] ?? 'Choose file:',
      description: json['description'],
    );
  }
}
