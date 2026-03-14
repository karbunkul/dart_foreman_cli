import 'dart:io';

import 'package:foreman_cli/src/config/variable_controller.dart';
import 'package:foreman_cli/src/config/variables/variables.dart'
    show ShellVariable;
import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  test('Should be return current directory', () async {
    final controller = VariableController()..inject(key: 'foo', value: 'bar');
    expect(controller.resolve('{{foo}}'), 'bar');
    final logger = Logger();

    final shellVar = ShellVariable.fromExec(name: 'currentDir', exec: 'pwd')
      ..attach(controller);

    await shellVar.resolve(logger);

    expect(controller.values['currentDir'], Directory.current.path);
  });
}
