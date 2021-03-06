@Timeout(Duration(seconds: 600))
import 'package:dcli/dcli.dart' hide equals;
import 'package:test/test.dart';

String baseURl =
    'https://raw.githubusercontent.com/bsutton/dcli/master/test/src/functions/fetch_downloads';
String? testFile;
void main() {
  group('Fetch Single', () {
    // Don't know how to test this as it writes directly to stdout.
    // Need some way to hook Stdout
    test('Fetch One', () {
      //Settings().setVerbose(enabled: true);
      withTempDir((testRoot) {
        withTempFile((sampleAac) {
          fetch(url: '$baseURl/sample.aac', saveToPath: sampleAac);
          expect(fileLength(sampleAac), equals(14951));
          delete(sampleAac);
        }, create: false);

        // withTempFile((sampleWav) {
        //   fetch(url: '$baseURl/sample.wav', saveToPath: sampleWav);
        //   expect(FileSync(sampleWav).length, equals(212948));
        //   delete(sampleWav);
        // }, create: false);
      });
    });

    test('Fetch One with Progress', () {
      withTempDir((testRoot) {
        withTempFile((sampleAac) {
          fetch(
              url: '$baseURl/sample.aac',
              saveToPath: sampleAac,
              fetchProgress: (progress) async {
                Terminal().overwriteLine('${progress.progress * 100} %');
              });
          expect(fileLength(sampleAac), equals(14951));
          delete(sampleAac);

          withTempFile((sampleWav) {
            fetch(
                url: '$baseURl/sample.wav',
                saveToPath: sampleWav,
                fetchProgress: (progress) async {
                  Terminal().overwriteLine('${progress.progress * 100} %');
                });
            expect(fileLength(sampleWav), equals(212948));
            delete(sampleWav);
          }, create: false);
        }, create: false);
      });
    });
  });

  group('Fetch Multi', () {
    test('Fetch  ', () {
      withTempDir((testRoot) {
        withTempFile((sampleAac) {
          withTempFile((sampleWav) {
            fetchMultiple(urls: [
              FetchUrl(
                  url: '$baseURl/sample.aac',
                  saveToPath: sampleAac,
                  progress: showProgress),
              FetchUrl(url: '$baseURl/sample.wav', saveToPath: sampleWav)
            ]);
            expect(fileLength(sampleAac), equals(14951));
            expect(fileLength(sampleWav), equals(212948));

            delete(sampleAac);
            delete(sampleWav);
          }, create: false);
        }, create: false);
      });
    });

    test('Fetch With Progress ', () {
      withTempDir((testRoot) {
        withTempFile((sampleAac) {
          withTempFile((sampleWav) {
            fetchMultiple(urls: [
              FetchUrl(
                  url: '$baseURl/sample.aac',
                  saveToPath: sampleAac,
                  progress: showProgress),
              FetchUrl(
                  url: '$baseURl/sample.wav',
                  saveToPath: sampleWav,
                  progress: showProgress)
            ]);
            expect(fileLength(sampleAac), equals(14951));
            expect(fileLength(sampleWav), equals(212948));
          }, create: false);
        }, create: false);
      });
    });
  });

  test('Fetch - shutdown bug', () {
    withTempFile((sampleAac) {
      fetch(
          url: '$baseURl/sample.aac',
          saveToPath: sampleAac,
          fetchProgress: (progress) async {
            Terminal().overwriteLine('${progress.progress * 100} %');
          });
      expect(fileLength(sampleAac), equals(14951));
    }, suffix: 'acc', create: false);

    final temp = withTempFile((sampleWav) {
      fetch(
          url: '$baseURl/sample.wav',
          saveToPath: sampleWav,
          fetchProgress: (progress) async {
            Terminal().overwriteLine('${progress.progress * 100} %');
          });
      expect(fileLength(sampleWav), equals(212948));
      print('finished');
      return sampleWav;
    }, suffix: 'wav', create: false);
    expect(exists(temp), isFalse);
  });
}

Future<void> showProgress(FetchProgress progress) async {
  Terminal().overwriteLine('${progress.progress * 100} %');
}
