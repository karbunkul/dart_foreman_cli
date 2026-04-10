part of 'variables.dart';

/// A variable that represents a boolean choice (yes/no).
final class ConfirmVariable extends Variable {
  /// The prompt message displayed to the user.
  final String prompt;

  /// The default value if the user just presses enter.
  final bool defaultValue;

  ConfirmVariable({
    required super.name,
    required this.prompt,
    this.defaultValue = true,
    super.description,
  }) : super(behavior: .confirm, variableType: .boolean);

  @override
  Future<ResolveResult> resolve(Logger logger) async {
    try {
      final value = logger.confirm(prompt, defaultValue: defaultValue);
      inject(value.toString());
      return ResolveResult.ok;
    } catch (e) {
      return ResolveResult.cancel;
    }
  }

  static ConfirmVariable import(Json json) {
    return ConfirmVariable(
      name: json['name'],
      prompt: json['prompt'] ?? 'Confirm ${json['name']}?',
      defaultValue: json['default'] ?? true,
      description: json['description'],
    );
  }
}
