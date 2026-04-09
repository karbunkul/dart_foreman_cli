part of 'config.dart';

/// The result of a variable resolution process.
enum ResolveResult {
  /// Resolution was successful.
  ok,

  /// Resolution failed, but the user/system may try again.
  retry,

  /// Resolution was aborted by the user or a critical error.
  cancel,
}

/// A base class representing a configuration variable.
///
/// Variables are used to store and resolve data required for brick generation.
/// Each variable has a [behavior] that defines how it obtains its value.
abstract base class Variable {
  /// The unique identifier of the variable.
  final String name;

  /// An optional description explaining the purpose of this variable.
  final String? description;

  /// The data type of the variable (e.g., string, boolean, number).
  final BrickVariableType variableType;

  /// Defines the strategy used to resolve the variable's value.
  final VariableBehavior behavior;

  Variable({
    required this.name,
    this.description,
    this.variableType = BrickVariableType.string,
    this.behavior = VariableBehavior.mason,
  });

  /// Abstract method to resolve the variable value.
  ///
  /// Implementation depends on the [behavior].
  /// Returns a [ResolveResult] indicating success or failure.
  Future<ResolveResult> resolve(Logger logger);

  /// Reference to the controller that manages the variable's state.
  @protected
  VariableController? _variableController;

  /// Attaches the variable to a [VariableController].
  ///
  /// This must be called before calling [resolve] or [inject].
  void attach(VariableController controller) {
    _variableController ??= controller;
  }

  /// Injects a resolved [value] into the global configuration state.
  ///
  /// Uses the [name] of this variable as the key.
  @protected
  void inject(String value) {
    _controller.inject(key: name, value: value);
  }

  /// Resolves a string containing placeholders using the current context.
  ///
  /// Example:
  /// ```dart
  /// // If name is 'project'
  /// variable.resolveTemplate('lib/src/{{name}}'); // returns 'lib/src/project'
  /// ```
  String resolveTemplate(String template) => _controller.resolve(template);

  /// Detaches the variable from its controller.
  void detach() => _variableController = null;

  /// Internal getter for the controller.
  ///
  /// Throws [VariableControllerNotAttachException] if the variable is not attached.
  VariableController get _controller {
    if (_variableController == null) {
      throw VariableControllerNotAttachException();
    }
    return _variableController!;
  }

  /// Factory method to create a specific [Variable] implementation from JSON.
  ///
  /// The [behavior] field in the JSON determines which subclass is instantiated.
  static Variable import(Json json) {
    final behavior = VariableBehavior.fromId(json['behavior']);

    return switch (behavior) {
      VariableBehavior.shell => ShellVariable.import(json),
      VariableBehavior.mason => MasonVariable.import(json),
      VariableBehavior.combine => CombineVariable.import(json),
      VariableBehavior.selectDirectory => SelectDirectoryVariable.import(json),
      VariableBehavior.select => SelectVariable.import(json),
      VariableBehavior.confirm => ConfirmVariable.import(json),
      VariableBehavior.selectFile => SelectFileVariable.import(json),
    };
  }

  @override
  String toString() {
    final fields = <String, dynamic>{
      'name': name,
      'description': description,
      'behavior': behavior.id,
      'variableType': variableType.toString().replaceAll(
        'BrickVariableType.',
        '',
      ),
    };

    if (this is ShellVariable) {
      final ShellVariable(:windows, :linux, :darwin) = this as ShellVariable;
      fields.putIfAbsent(
        'exec',
        () => {'windows': windows, 'linux': linux, 'darwin': darwin},
      );
    }

    if (this is SelectDirectoryVariable) {
      final SelectDirectoryVariable(:path, :prompt) =
          this as SelectDirectoryVariable;
      fields.putIfAbsent('path', () => path);
      fields.putIfAbsent('prompt', () => prompt);
    }

    if (this is SelectVariable) {
      final SelectVariable(:options, :prompt) = this as SelectVariable;
      fields.putIfAbsent('options', () => options);
      fields.putIfAbsent('prompt', () => prompt);
    }

    if (this is ConfirmVariable) {
      final ConfirmVariable(:defaultValue, :prompt) = this as ConfirmVariable;
      fields.putIfAbsent('default', () => defaultValue);
      fields.putIfAbsent('prompt', () => prompt);
    }

    if (this is SelectFileVariable) {
      final SelectFileVariable(:path, :filter, :prompt) =
          this as SelectFileVariable;
      fields.putIfAbsent('path', () => path);
      fields.putIfAbsent('filter', () => filter);
      fields.putIfAbsent('prompt', () => prompt);
    }

    if (this is CombineVariable) {
      final CombineVariable(:template) = this as CombineVariable;
      fields.putIfAbsent('template', () => template);
    }

    if (this is MasonVariable) {
      final MasonVariable(:prompt, :pattern) = this as MasonVariable;
      fields.putIfAbsent('prompt', () => prompt);
      fields.putIfAbsent('pattern', () => pattern);
    }

    return '$runtimeType($fields)';
  }
}
