import 'dart:io' show Platform, Process;

final class ShellCommand {
  final String linux;
  final String windows;
  final String darwin;

  ShellCommand({
    required this.linux,
    required this.windows,
    required this.darwin,
  });

  factory ShellCommand.exec(String command) {
    return ShellCommand(linux: command, windows: command, darwin: command);
  }

  String get command {
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

  Future<String> run({String? command}) async {
    final shell = Platform.isWindows ? 'cmd' : 'sh';
    final shellArg = Platform.isWindows ? '/c' : '-c';

    final res = await Process.run(shell, [shellArg, command ?? this.command]);
    if (res.exitCode == 0) {
      return res.stdout;
    } else {
      throw Exception(res.stderr);
    }
  }

  static ShellCommand import(dynamic value) {
    if (value is String) {
      return ShellCommand.exec(value);
    }

    if (value is Map) {
      final linux = value['linux'] as String?;
      final windows = value['windows'] as String?;
      final darwin = value['darwin'] as String?;
      final any = value['any'] as String?;

      return ShellCommand(
        linux: linux ?? any!,
        windows: windows ?? any!,
        darwin: darwin ?? any!,
      );
    }

    throw UnimplementedError();
  }
}
