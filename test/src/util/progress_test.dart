@Timeout(Duration(minutes: 5))
import 'package:dcli/dcli.dart' hide equals;
import 'package:test/test.dart';

import 'test_file_system.dart';

void main() {
// This is intended to demonstrate that we ouput data as it flows in
  // I'm not certain how to actually test that so for the
  // moment this test is disabled.
  test('Slow', () {
    TestFileSystem().withinZone((fs) {
      print(pwd);
      'bash ${join(fs.testScriptPath, 'general/bin/slow.sh')}'.forEach(print);
      expect(
          () => 'tail -n 5 badfilename.txt'.run, throwsA(isA<DCliException>()));
    });
  }, skip: true);

  test('toList', () {
    expect(find('*', workingDirectory: HOME, recursive: false).toList().length,
        isNot(equals(0)));
  });

  test('forEach', () {
    final list = <String>[];
    find('*', workingDirectory: HOME, recursive: false).forEach(list.add);
    expect(list.length, isNot(equals(0)));
  });
}
