import 'dart:io';

import 'package:path/path.dart';

import '../settings.dart';
import '../util/truepath.dart';
import 'function.dart';
import 'is.dart';

///
/// Copies the file [from] to the path [to].
///
/// ```dart
/// copy("/tmp/fred.text", "/tmp/fred2.text", overwrite=true);
/// ```
///
/// [to] may be a directory in which case the [from] filename is
/// used to construct the [to] files full path.
///
/// The [to] file must not exists unless [overwrite] is set to true.
///
/// The default for [overwrite] is false.
///
/// If an error occurs a [CopyException] is thrown.
void copy(String from, String to, {bool overwrite = false}) =>
    _Copy().copy(from, to, overwrite: overwrite);

class _Copy extends DCliFunction {
  void copy(String from, String to, {bool overwrite = false}) {
    var finalto = to;
    if (isDirectory(finalto)) {
      finalto = join(finalto, basename(from));
    }

    verbose(() => 'copy ${truepath(from)} -> ${truepath(finalto)}');

    if (overwrite == false && exists(finalto)) {
      throw CopyException(
          'The target file ${truepath(finalto)} already exists.');
    }

    try {
      File(from).copySync(finalto);
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      /// lets try and improve the message.
      /// We do these checks only on failure
      /// so in the most common case (everything is correct)
      /// we don't waste cycles on unnecessary work.
      if (!exists(from)) {
        throw CopyException('The from file ${truepath(from)} does not exists.');
      }
      if (!exists(dirname(to))) {
        throw CopyException(
            'The to directory ${truepath(dirname(to))} does not exists.');
      }

      throw CopyException(
          'An error occured copying ${truepath(from)} to ${truepath(finalto)}. '
          'Error: $e');
    }
  }
}

/// Throw when the [copy] function encounters an error.
class CopyException extends FunctionException {
  /// Throw when the [copy] function encounters an error.
  CopyException(String reason) : super(reason);
}
