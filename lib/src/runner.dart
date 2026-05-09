import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:io';

import 'package:args/args.dart' show ArgResults;
import 'package:foreman_cli/src/config/config.dart';
import 'package:path/path.dart' as p;
import 'package:args/command_runner.dart' show CommandRunner, Command;
import 'package:cli_completion/cli_completion.dart'
    show CompletionCommandRunner;

import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart' show loadYaml;

import 'commands/commands.dart' show BuildCommand;

const _keyVerbose = 'verbose';
const _keyVersion = 'version';
const _keyHelp = 'help';
const _keyProjectDirectory = 'project-dir';

const _foremanConfigFileName = 'foreman.yaml';

/// {@template foreman_runner}
/// A [CommandRunner] for the Foreman CLI.
///
/// It manages global flags, project directory discovery,
/// and configuration loading before executing commands.
/// {@endtemplate}
final class ForemanRunner extends CompletionCommandRunner<int> {
  final Logger _logger;
  bool _verbose = false;
  late Directory _projectDir;
  ConfigSpec? _config;
  bool _isInitialized = false;

  /// {@macro foreman_runner}
  ForemanRunner(this._logger)
    : super('foreman', 'A CLI tool for project automation.') {
    // flags
    argParser
      ..addFlag(
        _keyVerbose,
        abbr: 'v',
        negatable: false,
        help: 'Enable verbose logging.',
      )
      ..addFlag(
        _keyVersion,
        help: 'Reports the version of this tool.',
        defaultsTo: false,
        negatable: false,
      );
    // options
    argParser.addOption(
      _keyProjectDirectory,
      abbr: 'p',
      help: 'The path to the project directory.',
    );

    // commands
    addCommand(BuildCommand());
  }

  @override
  String get usageFooter {
    return '\n(c) 2026, Alexander Pokhodyun (karbunkul)';
  }

  /// Returns the [File] pointing to the `foreman.yaml` configuration file.
  File get configFile =>
      File(p.join(_projectDir.absolute.path, _foremanConfigFileName));

  /// Whether a configuration file exists in the current project directory.
  bool get hasConfigFile => configFile.existsSync();

  /// Configures the logger level based on the verbose flag.
  void _verboseSetup(ArgResults topLevelResults) {
    if (topLevelResults[_keyVerbose] == true) {
      _verbose = true;
      _logger.level = Level.verbose;
    }
  }

  /// Sets up the project directory by checking arguments or searching upward.
  void _projectDirSetup(ArgResults topLevelResults) {
    final path = topLevelResults[_keyProjectDirectory] as String?;

    if (path != null) {
      _projectDir = Directory(path);
    } else {
      final projectDir = _findProjectDir(Directory.current);
      _projectDir = projectDir ?? Directory.current;
    }
  }

  /// Recursively searches for a directory containing `foreman.yaml` starting from [dir].
  Directory? _findProjectDir(Directory dir) {
    final hasConfigFile = File(
      p.join(dir.path, _foremanConfigFileName),
    ).existsSync();

    if (hasConfigFile) return dir;

    if (dir.parent.path == dir.path) {
      return null;
    }

    return _findProjectDir(dir.parent);
  }

  /// Loads the [ConfigSpec] from the configuration file if it exists.
  void _configSetup(ArgResults topLevelResults) {
    if (hasConfigFile) {
      final yaml = loadYaml(configFile.readAsStringSync()) as Map;
      final json = jsonDecode(jsonEncode(yaml));

      _config = ConfigSpec.import(json);
      _logger.detail('🚀 Load config file: ${configFile.absolute.path}');
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name == 'completion' ||
        topLevelResults.wasParsed(_keyHelp)) {
      return super.runCommand(topLevelResults);
    }

    if (topLevelResults.wasParsed(_keyVersion)) {
      return _versionSetup();
    }

    if (topLevelResults.wasParsed(_keyHelp)) {
      return super.runCommand(topLevelResults);
    }

    if (!_isInitialized) {
      _verboseSetup(topLevelResults);
      _projectDirSetup(topLevelResults);
      _configSetup(topLevelResults);
      _isInitialized = true;
    }

    return super.runCommand(topLevelResults);
  }

  Future<int?> _versionSetup() async {
    _logger.info('🏗️  Foreman 0.9.8');
    _logger.detail('Author: Alexander Pokhodyun (karbunkul)');
    _logger.detail('GitHub: https://github.com/karbunkul');

    try {
      final res = await Process.run('mason', ['--version']);
      if (res.exitCode == 0) {
        final version = res.stdout.toString().trim();
        _logger.info('🧱  $version');
      } else {
        _logger.detail('Mason CLI is not installed.');
      }
    } catch (_) {
      _logger.detail('Mason CLI is not available in PATH.');
    }

    return ExitCode.success.code;
  }

  @override
  bool get enableAutoInstall => false;
}

/// {@template foreman_command}
/// The base class for all Foreman CLI commands.
///
/// Provides convenient access to the [runner], [logger], and [config].
/// {@endtemplate}
abstract base class ForemanCommand extends Command<int> {
  @override
  ForemanRunner get runner => super.runner as ForemanRunner;

  /// Access to the logger instance.
  Logger get logger => runner._logger;

  /// Whether verbose logging is enabled.
  bool get verbose => runner._verbose;

  /// The project directory for the current execution.
  Directory get projectDir => runner._projectDir;

  /// The parsed configuration specification, if available.
  ConfigSpec? get config => runner._config;

  /// Whether a configuration was successfully loaded.
  bool get hasConfig => config != null;

  /// The configuration file used by the runner.
  File get configFile => runner.configFile;

  /// The file path for the Mason bricks cache.
  File get masonBricksCacheFile {
    return File(p.join(projectDir.absolute.path, '.mason/bricks.json'));
  }

  /// Helper method to load and parse a YAML file into a JSON-compatible [Map].
  Map<String, dynamic> loadYamlFromFile(File file) {
    final yaml = loadYaml(file.absolute.readAsStringSync());
    final json = jsonDecode(jsonEncode(yaml));
    return json as Map<String, dynamic>;
  }
}

/// Extension on [Logger] to provide additional UI helpers.
extension Divider on Logger {
  /// Prints a visual divider line to the console.
  void divider() {
    info(darkGray.wrap('-' * 80));
  }
}
