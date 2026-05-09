part of 'commands.dart';

/// {@template list_command}
/// A command that lists all available blueprints defined in the `foreman.yaml` configuration.
///
/// It displays the blueprint name, description (if available), and associated tags.
/// {@endtemplate}
final class ListCommand extends ForemanCommand {
  /// {@macro list_command}
  ListCommand();

  @override
  String get description => 'Lists all available blueprints from foreman.yaml';

  @override
  String get name => 'list';

  @override
  FutureOr<int>? run() async {
    if (!hasConfig) {
      throw ConfigNotFoundException(path: configFile.parent);
    }

    final blueprints = config?.all ?? [];

    if (blueprints.isEmpty) {
      logger.info('No blueprints found in ${configFile.path}');
      return ExitCode.success.code;
    }

    logger.info('Available blueprints:');
    logger.divider();

    for (final blueprint in blueprints) {
      logger.info(cyan.wrap(blueprint.name) ?? blueprint.name);

      if (blueprint.tags.isNotEmpty) {
        logger.info('  ${darkGray.wrap('Tags:')}');
        for (final tag in blueprint.tags) {
          logger.info('    ${darkGray.wrap('•')} $tag');
        }
      }

      if (blueprint.variables.isNotEmpty) {
        logger.info('  ${darkGray.wrap('Vars:')}');
        for (final variable in blueprint.variables) {
          final behavior = variable.behavior.id != 'mason'
              ? ' ${darkGray.wrap('(${variable.behavior.id})')}'
              : '';
          logger.info('    ${darkGray.wrap('•')} ${variable.name}$behavior');
        }
      }

      logger.info('  ${darkGray.wrap('Bricks:')}');
      for (final brick in blueprint.bricks) {
        logger.info('    ${darkGray.wrap('└─')} 🧱 ${brick.name}');
        if (brick.variables.isNotEmpty) {
          for (final variable in brick.variables) {
            final behavior = variable.behavior.id != 'mason'
                ? ' ${darkGray.wrap('(${variable.behavior.id})')}'
                : '';
            logger.info(
              '       ${darkGray.wrap('•')} ${variable.name}$behavior',
            );
          }
        }
      }
      logger.info('');
    }

    return ExitCode.success.code;
  }
}
