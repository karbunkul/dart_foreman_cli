import 'package:foreman_cli/src/config/variable_controller.dart';
import 'package:test/test.dart';

void main() {
  group('VariableController', () {
    late VariableController controller;

    setUp(() {
      controller = VariableController();
    });

    test('Should resolve basic variable', () {
      controller.inject(key: 'name', value: 'world');
      expect(controller.resolve('Hello, {{name}}!'), 'Hello, world!');
    });

    test('Should resolve pascalCase()', () {
      controller.inject(key: 'foo', value: 'hello_world');
      expect(controller.resolve('{{foo.pascalCase()}}'), 'HelloWorld');
    });

    test('Should resolve snakeCase()', () {
      controller.inject(key: 'foo', value: 'HelloWorld');
      expect(controller.resolve('{{foo.snakeCase()}}'), 'hello_world');
    });

    test('Should resolve camelCase()', () {
      controller.inject(key: 'foo', value: 'hello_world');
      expect(controller.resolve('{{foo.camelCase()}}'), 'helloWorld');
    });

    test('Should resolve paramCase()', () {
      controller.inject(key: 'foo', value: 'helloWorld');
      expect(controller.resolve('{{foo.paramCase()}}'), 'hello-world');
    });

    test('Should resolve constantCase()', () {
      controller.inject(key: 'foo', value: 'helloWorld');
      expect(controller.resolve('{{foo.constantCase()}}'), 'HELLO_WORLD');
    });

    test('Should resolve fileNameWithoutExt()', () {
      controller.inject(key: 'path', value: 'lib/src/models/user_profile.dart');
      expect(
        controller.resolve('{{path.fileNameWithoutExt()}}'),
        'user_profile',
      );
    });

    test('Should resolve fileNameWithoutExt() for file without directory', () {
      controller.inject(key: 'file', value: 'README.md');
      expect(controller.resolve('{{file.fileNameWithoutExt()}}'), 'README');
    });

    test('Should handle multiple transformations in one string', () {
      controller.inject(key: 'name', value: 'my_feature');
      final template =
          'Class {{name.pascalCase()}} in {{name.snakeCase()}}.dart';
      expect(
        controller.resolve(template),
        'Class MyFeature in my_feature.dart',
      );
    });

    test('Should handle spaces in tags', () {
      controller.inject(key: 'foo', value: 'bar');
      expect(controller.resolve('{{ foo.pascalCase() }}'), 'Bar');
    });

    test('Should return original if method is unknown', () {
      controller.inject(key: 'foo', value: 'bar');
      // Текущая реализация RegExp и _ResolveMethod.fromMethod вернет 'original'
      expect(controller.resolve('{{foo.unknownMethod()}}'), 'bar');
    });
  });
}
