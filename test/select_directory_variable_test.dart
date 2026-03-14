import 'package:foreman_cli/src/config/variable_controller.dart';
import 'package:foreman_cli/src/config/variables/variables.dart'
    show SelectDirectoryVariable;
import 'package:test/test.dart';

void main() {
  test('Should be return directory list', () async {
    final controller = VariableController()
      ..inject(key: 'foo', value: 'example');

    final selectDir = SelectDirectoryVariable(name: 'feature', path: '{{foo}}')
      ..attach(controller);

    final dirs = selectDir.values;
    expect(dirs.length, 3);
    expect(dirs.first, '.mason');

    print(dirs);
  });
}
