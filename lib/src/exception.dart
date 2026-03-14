import 'dart:io' show File, Directory;

import 'package:mason/mason.dart';

import 'config/config.dart' show ConfigEntityType;

/// Base class for all exceptions thrown by the Foreman CLI.
///
/// Contains an [exitCode] to be used by the runner and a descriptive [message].
base class ForemanException implements Exception {
  /// The exit code that the CLI should return.
  final ExitCode exitCode;

  /// A human-readable description of the error.
  final String message;

  ForemanException({required this.exitCode, required this.message});

  @override
  String toString() => message;
}

/// Exception thrown when a specific brick cannot be located.
///
/// Example:
/// ```dart
/// throw BrickNotFoundException(
///   brickName: 'my_brick',
///   configFile: File('foreman.yaml'),
/// );
/// ```
final class BrickNotFoundException extends ForemanException {
  final String brickName;
  final File configFile;

  BrickNotFoundException({required this.brickName, required this.configFile})
    : super(
        exitCode: ExitCode.software,
        message: 'Brick "$brickName" not found, in ${configFile.absolute.path}',
      );
}

/// Exception thrown when the `foreman.yaml` configuration file is missing.
///
/// Example:
/// ```dart
/// throw ConfigNotFoundException(path: Directory.current);
/// ```
final class ConfigNotFoundException extends ForemanException {
  final Directory path;

  ConfigNotFoundException({required this.path})
    : super(
        exitCode: ExitCode.software,
        message: 'Config file foreman.yaml not found in ${path.absolute.path}',
      );
}

/// Exception thrown when there is a type mismatch during configuration parsing.
///
/// Example:
/// ```dart
/// throw EntityCastException(
///   type: ConfigEntityType.brick,
///   field: 'vars',
/// );
/// ```
final class EntityCastException extends ForemanException {
  final ConfigEntityType type;
  final String field;

  EntityCastException({required this.type, required this.field})
    : super(
        exitCode: ExitCode.software,
        message:
            'Cast error in field "$field" for config entity type "${type.id}"',
      );
}

/// Exception thrown when attempting to access a variable controller that has
/// not been properly initialized or attached.
final class VariableControllerNotAttachException extends ForemanException {
  VariableControllerNotAttachException()
    : super(
        exitCode: ExitCode.software,
        message: 'Variable controller not attach',
      );
}

/// Exception thrown when a variable name is duplicated within the same scope.
///
/// If [brickName] is provided, the error refers to a brick's local variables;
/// otherwise, it refers to global variables.
///
/// Example:
/// ```dart
/// throw DuplicateVariableException('api_key', brickName: 'logger');
/// ```
base class DuplicateVariableException extends ForemanException {
  final String variableName;
  final String? brickName;

  DuplicateVariableException(this.variableName, {this.brickName})
    : super(
        message: _buildMessage(variableName, brickName),
        exitCode: ExitCode.software,
      );

  static String _buildMessage(String name, String? brick) {
    final context = brick != null ? 'in brick "$brick"' : 'in global variables';

    return 'Variable "$name" is already defined $context.';
  }
}
