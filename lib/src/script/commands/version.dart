import 'dart:io';

import '../../../dcli.dart';
import '../../functions/which.dart';
import '../../settings.dart';
import '../../util/ansi_color.dart';
import '../../util/dcli_paths.dart';
import '../../util/recase.dart';
import '../../util/runnable_process.dart';
import '../command_line_runner.dart';
import '../flags.dart';
import 'commands.dart';

///
class VersionCommand extends Command {
  ///
  VersionCommand() : super(_commandName);

  static const String _commandName = 'version';

  @override
  int run(List<Flag> selectedFlags, List<String> subarguments) {
    if (subarguments.isNotEmpty) {
      throw InvalidArguments(
          "'dcli version' does not take any arguments. Found $subarguments");
    }

    final appname = DCliPaths().dcliName;

    var location = which(appname).path;

    if (location == null) {
      printerr(red('Error: dcli is not on your path. Run "dcli install"'));
    }

    location ??= 'Not installed';
    // expand symlink
    location = File(location).resolveSymbolicLinksSync();

    print(green('${ReCase.titleCase(appname)} '
        'Version: ${Settings().version}, Located at: $location'));

    return 0;
  }

  @override
  String description() =>
      """Running 'dcli version' displays the dcli version and path.""";

  @override
  String usage() => 'version';

  @override
  List<String> completion(String word) => <String>[];

  @override
  List<Flag> flags() => [];
}
