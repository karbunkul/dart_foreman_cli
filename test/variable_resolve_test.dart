import 'package:foreman_cli/src/config/variable_controller.dart';
import 'package:test/test.dart';

void main() {
  test('Should be return current directory', () async {
    final controller = VariableController()..inject(key: 'foo', value: 'bar');
    expect(controller.resolve('foo {{foo.pascalCase()}}'), 'foo Bar');
  });
}
