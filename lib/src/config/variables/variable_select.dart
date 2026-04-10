part of 'variables.dart';

/// A variable that allows the user to select one option from a fixed list.
final class SelectVariable extends Variable {
  /// The list of available options for selection.
  final List<String> options;

  /// The prompt message displayed to the user.
  final String prompt;

  SelectVariable({
    required super.name,
    required this.options,
    required this.prompt,
    super.description,
  }) : super(behavior: .select);

  @override
  Future<ResolveResult> resolve(Logger logger) async {
    try {
      final value = prompts.choose(prompt, options, interactive: false);

      if (value == null) {
        return ResolveResult.cancel;
      }

      inject(value);
      return ResolveResult.ok;
    } catch (e) {
      return ResolveResult.cancel;
    }
  }

  static SelectVariable import(Json json) {
    final options = ConfigEntity.castFieldTo<List>(
      field: 'options',
      value: json['options'],
      entityType: .variable,
    ).map((e) => e.toString()).toList();

    return SelectVariable(
      name: json['name'],
      options: options,
      prompt: json['prompt'] ?? 'Select ${json['name']}:',
      description: json['description'],
    );
  }
}
