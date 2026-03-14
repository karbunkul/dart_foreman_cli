part of 'variables.dart';

/// A variable that resolves its value by executing a shell command.
///
/// Supports platform-specific commands for Linux, Windows, and macOS.
final class ShellVariable extends Variable {
  /// The command to execute on Linux systems.
  final String linux;

  /// The command to execute on Windows systems.
  final String windows;

  /// The command to execute on macOS (Darwin) systems.
  final String darwin;

  /// Creates a [ShellVariable] with specific commands for each platform.
  ShellVariable({
    required super.name,
    super.description,
    super.variableType,
    required this.linux,
    required this.windows,
    required this.darwin,
  }) : super(behavior: .shell);

  /// Creates a [ShellVariable] that uses the same command for all platforms.
  factory ShellVariable.fromExec({
    required String name,
    String? description,
    required String exec,
  }) {
    return ShellVariable(
      name: name,
      linux: exec,
      windows: exec,
      darwin: exec,
      description: description,
    );
  }

  /// Selects the appropriate command based on the current operating system.
  String get _command {
    if (Platform.isWindows) {
      return windows;
    }

    if (Platform.isLinux) {
      return linux;
    }

    if (Platform.isMacOS) {
      return darwin;
    }

    throw UnimplementedError(
      'Unsupported platform: ${Platform.operatingSystem}',
    );
  }

  /// Imports a [ShellVariable] from a JSON map.
  ///
  /// The `exec` field can be a simple string (used for all platforms)
  /// or an object with platform-specific keys:
  /// ```json
  /// {
  ///   "name": "project_version",
  ///   "exec": {
  ///     "any": "git describe --tags",
  ///     "windows": "git describe --tags --long"
  ///   }
  /// }
  /// ```
  static ShellVariable import(Json json) {
    final execRaw = json['exec'];
    final isExec = execRaw is String;

    final name = ConfigEntity.castFieldTo<String>(
      field: 'name',
      value: json['name'],
      entityType: .variable,
    );

    final description = json['description'] as String?;

    if (isExec) {
      final exec = ConfigEntity.castFieldTo<String>(
        field: 'exec',
        value: json['exec'],
        entityType: .variable,
      );

      return ShellVariable.fromExec(
        name: name,
        exec: exec,
        description: description,
      );
    } else {
      final exec = execRaw as Json? ?? {};
      final any = exec['any'] as String?;
      final windows = exec['windows'] as String? ?? any;
      final linux = exec['linux'] as String? ?? any;
      final darwin = exec['darwin'] as String? ?? any;

      try {
        return ShellVariable(
          name: name,
          linux: linux!,
          windows: windows!,
          darwin: darwin!,
          description: description,
        );
      } on Object {
        throw EntityCastException(type: .variable, field: 'exec');
      }
    }
  }

  /// Executes the shell command and stores the trimmed stdout as the variable's value.
  ///
  /// Returns [ResolveResult.ok] if the command exits with code 0,
  /// otherwise returns [ResolveResult.cancel].
  @override
  Future<ResolveResult> resolve(Logger logger) async {
    final resolvedCmd = resolveTemplate(_command);

    final shell = Platform.isWindows ? 'cmd' : 'sh';
    final shellArg = Platform.isWindows ? '/c' : '-c';

    final res = await Process.run(shell, [shellArg, resolvedCmd]);
    if (res.exitCode == 0) {
      inject(res.stdout.toString().trim());
      return .ok;
    } else {
      return .cancel;
    }
  }
}
