part of 'variables.dart';

/// A variable that combines other variables using a template.
///
/// This behavior does not prompt the user. It resolves the [template]
/// using the current variable context.
final class CombineVariable extends Variable {
  /// The mustache template to resolve.
  final String template;

  CombineVariable({
    required super.name,
    required this.template,
    super.description,
  }) : super(behavior: .combine);

  @override
  Future<ResolveResult> resolve(Logger logger) async {
    try {
      final value = resolveTemplate(template);
      inject(value);
      return ResolveResult.ok;
    } catch (e) {
      logger.err('Error resolving combine variable "${super.name}": $e');
      return ResolveResult.cancel;
    }
  }

  static CombineVariable import(Json json) {
    return CombineVariable(
      name: json['name'],
      template: json['template'] ?? '',
      description: json['description'],
    );
  }
}
