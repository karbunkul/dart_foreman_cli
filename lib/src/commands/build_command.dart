part of 'commands.dart';

const _keyBlueprint = 'blueprint';
const _keyTag = 'tag';

/// A type alias representing the state and generator of a blueprint.
///
/// Contains a map of resolved variables ([states]) and the [MasonGenerator].
typedef BlueprintState = (Map<String, String> states, MasonGenerator generator);

/// {@template build_command}
/// A command that builds a blueprint defined in the `foreman.yaml` configuration.
///
/// It resolves variables, shows a preview of the files to be generated,
/// and prompts the user for confirmation before writing to disk.
/// {@endtemplate}
final class BuildCommand extends ForemanCommand {
  /// {@macro build_command}
  BuildCommand() {
    argParser.addOption(
      _keyBlueprint,
      abbr: 'b',
      help: 'Blueprint name from config',
    );
    argParser.addFlag(
      _keyTag,
      abbr: 't',
      negatable: false,
      help: 'Filter by tags. If no tags provided, shows interactive selector.',
    );
  }

  @override
  String get description {
    return 'Builds a blueprint defined in your foreman.yaml';
  }

  @override
  String get name => 'build';

  /// Cached mason brick paths loaded from the mason cache file.
  Map<String, dynamic>? _caches;

  @override
  FutureOr<int>? run() async {
    if (Directory.current.path != projectDir.path) {
      logger.detail(
        '🚀 Foreman project directory: ${projectDir.absolute.path}',
      );
    }

    if (!hasConfig) {
      throw ConfigNotFoundException(path: configFile.parent);
    }

    await _buildBlueprint();

    return ExitCode.success.code;
  }

  /// Orchestrates the blueprint building process.
  ///
  /// 1. Selects the blueprint.
  /// 2. Resolves variables for each brick.
  /// 3. Generates a preview.
  /// 4. Asks for confirmation before final generation.
  Future<void> _buildBlueprint() async {
    final blueprint = _getBlueprint();
    await _loadMasonCache();

    for (final brick in blueprint.bricks) {
      final controller = VariableController();
      logger.detail('🚀 Brick: ${cyan.wrap(brick.name)}');

      final oldDir = Directory.current;
      Directory.current = projectDir.absolute;

      final states = await blueprint.resolveBrickVariables(
        brickName: brick.name,
        logger: logger,
        controller: controller,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      Directory.current = oldDir;

      final brickName = brick.name;
      final targetPath = Directory(
        path.join(projectDir.path, controller.resolve(brick.path ?? '')),
      ).absolute;

      final generator = await _getGenerator(brickName);
      final previewTarget = PreviewGeneratorTarget();

      await generator.generate(
        previewTarget,
        vars: states,
        fileConflictResolution: FileConflictResolution.prompt,
        logger: logger,
      );

      logger.divider();
      logger.info('🏗️  Construction plan for: $brickName');
      logger.info(
        cyan.wrap(targetPath.path.replaceAll(projectDir.absolute.path, '.')),
      );
      logger.divider();

      _printBlueprintSummary(List.of(previewTarget.generatedPaths));

      logger.info(
        '\n✨ Total: ${previewTarget.generatedPaths.length} files to build',
      );
      logger.divider();

      final confirm = logger.confirm(
        'Do you want to continue?',
        defaultValue: true,
      );

      if (confirm) {
        await generator.generate(
          DirectoryGeneratorTarget(targetPath),
          vars: states,
          fileConflictResolution: FileConflictResolution.prompt,
          logger: logger,
        );

        if (brick.afterScripts != null) {
          for (final script in brick.afterScripts!) {
            try {
              final command = controller.resolve(script.command);
              print(command);
              print(Directory.current.path);
              await script.run(command: command);
            } catch (e) {
              logger.err(e.toString());
            }
          }
        }
      }
    }
  }

  /// Prints a visual tree representation of the files that will be generated.
  ///
  /// [paths] is a list of relative file paths.
  void _printBlueprintSummary(List<String> paths) {
    paths.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final Map<String, dynamic> tree = {};
    for (var path in paths) {
      var current = tree;
      for (var part in path.split('/')) {
        current = current.putIfAbsent(part, () => <String, dynamic>{});
      }
    }

    void render(Map<String, dynamic> nodes, [String prefix = '']) {
      final keys = nodes.keys.toList();
      for (var i = 0; i < keys.length; i++) {
        final key = keys[i];
        final isLast = i == keys.length - 1;
        final isDir = (nodes[key] as Map).isNotEmpty;

        final marker = isLast ? '└── ' : '├── ';
        final icon = isDir ? '📁 ' : '📄 ';

        print('$prefix$marker$icon$key');

        if (isDir) {
          render(
            nodes[key] as Map<String, dynamic>,
            prefix + (isLast ? '    ' : '│   '),
          );
        }
      }
    }

    render(tree);
  }

  /// Retrieves a [MasonGenerator] for the specified [brickName] using the local cache.
  Future<MasonGenerator> _getGenerator(String brickName) async {
    await _loadMasonCache();
    final brickPath = _caches![brickName] as String;
    final brick = Brick.path(brickPath);
    return MasonGenerator.fromBrick(brick);
  }

  /// Loads the Mason bricks cache into memory if it hasn't been loaded yet.
  ///
  /// Throws a [ForemanException] if the cache file is missing.
  Future<void> _loadMasonCache() async {
    if (_caches != null) {
      return;
    }

    final bricksFile = masonBricksCacheFile;

    if (!bricksFile.existsSync()) {
      throw ForemanException(
        exitCode: ExitCode.software,
        message: 'Mason cache not found',
      );
    }

    final caches = loadYamlFromFile(bricksFile);
    _caches = caches;
    return;
  }

  /// Determines which [BlueprintSpec] to use based on CLI arguments or user input.
  ///
  /// If a name is provided via `--blueprint`, it validates it.
  /// If only one blueprint exists, it selects it automatically.
  /// Otherwise, it prompts the user to choose from the available blueprints.
  BlueprintSpec _getBlueprint() {
    final blueprintArg = argResults?[_keyBlueprint] as String?;

    if (blueprintArg != null && config != null) {
      if (config!.has(blueprintArg)) {
        return config![blueprintArg]!;
      } else {
        throw BrickNotFoundException(
          brickName: blueprintArg,
          configFile: configFile,
        );
      }
    }

    Iterable<BlueprintSpec> blueprints = config?.all ?? [];

    final bool tagWasParsed = argResults?.wasParsed(_keyTag) ?? false;

    if (tagWasParsed) {
      List<String> selectedTags;
      final rest = argResults?.rest ?? [];

      if (rest.isEmpty) {
        final allTags = blueprints.expand((b) => b.tags).toSet().toList()
          ..sort();
        if (allTags.isEmpty) {
          logger.warn('No tags found in blueprints.');
          selectedTags = [];
        } else {
          final tag = prompts.choose(
            'Select tag to filter blueprints',
            allTags,
            interactive: false,
          );
          selectedTags = tag != null ? [tag] : [];
        }
      } else {
        selectedTags = rest;
      }

      if (selectedTags.isNotEmpty) {
        blueprints = blueprints.where(
          (b) => b.tags.any((t) => selectedTags.contains(t)),
        );
      }
    }

    if (blueprints.isEmpty) {
      throw ForemanException(
        exitCode: ExitCode.config,
        message: 'No blueprints found matching the specified criteria.',
      );
    }

    if (blueprints.length == 1) {
      final brick = blueprints.first;
      logger.info(
        'Using the only available $_keyBlueprint: ${cyan.wrap(brick.name)}',
      );
      return brick;
    }

    final allKeys = blueprints.map((b) => b.name).toList()..sort();

    final brickName = prompts.choose(
      'Choose $_keyBlueprint',
      allKeys,
      interactive: false,
    );

    final brick = config![brickName!]!;

    logger.info(
      '${lightGreen.wrap('✓')} Selected $_keyBlueprint: ${cyan.wrap(brick.name)}',
    );

    return brick;
  }
}
