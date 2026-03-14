import 'dart:io' show Directory, Platform, Process;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'package:foreman_cli/src/exception.dart' show EntityCastException;

import '../config.dart' show ConfigEntity, Json, Variable, ResolveResult;

part 'variable_select_directory.dart';
part 'variable_shell.dart';
part 'variable_mason.dart';
