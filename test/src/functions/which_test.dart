import 'dart:io';

import 'package:dcli/dcli.dart' hide equals;
import 'package:test/test.dart';

void main() {
  test('which ...', () async {
    expect(which('ls').path, equals('/usr/bin/ls'));
    expect(which('ls').found, equals(true));
    expect(which('ls').notfound, equals(false));
    expect(which('ls').paths.length, equals(1));
  }, skip: Platform.isWindows);

  test('which ...', () async {
    expect(which('regedit.exe').path, equals(r'C:\Windows\regedit.exe'));
    expect(which('regedit.exe').found, equals(true));
    expect(which('regedit.exe').notfound, equals(false));
    expect(which('regedit.exe').paths.length, equals(1));

    expect(which('regedit').path!.toLowerCase(),
        equals(r'C:\Windows\regedit.exe'.toLowerCase()));
  }, skip: !Platform.isWindows);
}
