import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String workflow;
  late String androidBuild;

  setUpAll(() async {
    workflow =
        await _repositoryFile(
          '.github/workflows/genshin-mobile-release-example.yml',
        ).readAsString();
    androidBuild =
        await _repositoryFile(
          'genshin-builder-mobile/android/app/build.gradle.kts',
        ).readAsString();
  });

  test('release workflow pins Flutter and validates the backend URL', () {
    expect(workflow, contains('flutter-version: "3.44.5"'));
    expect(
      workflow,
      contains(
        r'GENSHIN_BUILDER_API_BASE_URL: ${{ secrets.GENSHIN_BUILDER_API_BASE_URL }}',
      ),
    );
    expect(
      workflow,
      contains('GENSHIN_BUILDER_API_BASE_URL is not configured'),
    );
    expect(workflow, contains('parsed.scheme != "https"'));
    expect(workflow, contains('must not contain whitespace'));
    expect(workflow, contains('host == "10.0.2.2"'));
    expect(workflow, contains('is_loopback'));
  });

  test('release workflow injects the backend URL and keeps hardening', () {
    expect(
      workflow,
      contains(
        r'--dart-define=GENSHIN_BUILDER_API_BASE_URL=${GENSHIN_BUILDER_API_BASE_URL}',
      ),
    );
    expect(workflow, contains('--obfuscate'));
    expect(workflow, contains('--split-debug-info=build/debug-info'));
    expect(workflow, contains('flutter build appbundle --release'));
    expect(workflow, contains('genshin-mobile-aab'));
    expect(
      workflow,
      contains(r'${{ secrets.ANDROID_UPLOAD_KEYSTORE_BASE64 }}'),
    );
  });

  test('Android release signing remains fail-closed and optimized', () {
    expect(
      androidBuild,
      contains('signingConfig = signingConfigs.getByName("release")'),
    );
    expect(androidBuild, isNot(contains('getByName("debug")')));
    expect(androidBuild, contains('isMinifyEnabled = true'));
    expect(androidBuild, contains('isShrinkResources = true'));
    expect(androidBuild, contains('throw GradleException'));
  });
}

File _repositoryFile(String relativePath) {
  var directory = Directory.current.absolute;
  while (true) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}',
    );
    if (candidate.existsSync()) return candidate;
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Repository root was not found.');
    }
    directory = parent;
  }
}
