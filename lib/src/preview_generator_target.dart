import 'package:mason/mason.dart'
    show GeneratorTarget, GeneratedFile, Logger, OverwriteRule;

/// A custom [GeneratorTarget] designed to preview the files that would be
/// generated without actually writing them to the file system.
///
/// This is useful for dry-run scenarios where you want to collect the paths
/// of the files that the generator intends to create.
///
/// Example:
/// ```dart
/// final target = PreviewGeneratorTarget();
/// await generator.generate(target, vars: vars);
/// print(target.generatedPaths);
/// ```
final class PreviewGeneratorTarget extends GeneratorTarget {
  /// Internal list of paths that were "created" during the generation process.
  final List<String> _paths = [];

  /// Returns an unmodifiable list of all file paths that were processed
  /// by this generator target.
  List<String> get generatedPaths => List.unmodifiable(_paths);

  /// Captures the [path] of the file to be created and adds it to [_paths].
  ///
  /// Instead of writing to disk, it returns a [GeneratedFile.skipped] to
  /// ensure no physical files are modified.
  @override
  Future<GeneratedFile> createFile(
    String path,
    List<int> contents, {
    Logger? logger,
    OverwriteRule? overwriteRule,
  }) async {
    _paths.add(path);
    return GeneratedFile.skipped(path: path);
  }
}
