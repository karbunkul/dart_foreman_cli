import 'dart:io';

import 'package:foreman_cli/foreman_cli.dart';
import 'package:mason/mason.dart' show Logger, ExitCode;
import 'package:mason_logger/mason_logger.dart' show LogTheme, darkGray;

Future<void> main(List<String> args) async {
  final logger = _loggerSetup();

  try {
    final exitCode = await ForemanRunner(logger).run(args);
    exit(exitCode ?? ExitCode.success.code);
  } on ForemanException catch (e) {
    logger.err('💥 Fatal error: ${e.message}');
    exit(e.exitCode.code);
  } catch (e, stackTrace) {
    logger.err('💥 Fatal error: $e');
    if (args.contains('--verbose') || args.contains('-v')) {
      logger.detail(stackTrace.toString());
    }
    exit(ExitCode.software.code);
  }
}

Logger _loggerSetup() {
  return Logger(theme: LogTheme(detail: (value) => darkGray.wrap(value)));
}
