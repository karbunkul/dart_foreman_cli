import 'package:foreman_cli/src/config/variable_controller.dart';
import 'package:test/test.dart';

void main() {
  group('Variable Types Resolution', () {
    late VariableController controller;

    setUp(() {
      controller = VariableController();
    });

    test('Should resolve boolean variable (from ConfirmVariable)', () {
      controller.inject(key: 'is_enabled', value: true);
      expect(controller.resolve('Status: {{is_enabled}}'), 'Status: true');

      controller.inject(key: 'is_enabled', value: false);
      expect(controller.resolve('Status: {{is_enabled}}'), 'Status: false');
    });

    test('Should resolve string variable (from SelectVariable)', () {
      controller.inject(key: 'env', value: 'production');
      expect(controller.resolve('Running in {{env}}'), 'Running in production');
    });

    test('Should resolve path variable (from SelectFileVariable)', () {
      controller.inject(key: 'file', value: 'src/main.dart');
      expect(
        controller.resolve('Target: {{file.fileNameWithoutExt()}}'),
        'Target: main',
      );
    });

    test('Should resolve combine variables sequentially', () {
      // Имитируем работу CombineVariable
      controller.inject(key: 'root', value: 'packages');
      controller.inject(key: 'feature', value: 'auth');

      final fullPath = controller.resolve('{{root}}/{{feature}}/src');
      controller.inject(key: 'full_path', value: fullPath);

      expect(
        controller.resolve('Directory: {{full_path}}'),
        'Directory: packages/auth/src',
      );
    });

    test('Should handle mixed types in template', () {
      controller.inject(key: 'name', value: 'Foreman');
      controller.inject(key: 'is_pro', value: true);
      controller.inject(key: 'version', value: '1.0.0');

      final template = 'App: {{name}}, Pro: {{is_pro}}, v{{version}}';
      expect(controller.resolve(template), 'App: Foreman, Pro: true, v1.0.0');
    });

    test('Should not escape slashes in paths', () {
      controller.inject(key: 'path', value: 'a/b/c');
      // Проверяем, что htmlEscapeValues: false работает
      expect(controller.resolve('{{path}}'), 'a/b/c');
    });
  });
}
