import 'package:flutter_test/flutter_test.dart';
import 'package:todocat/services/app_update_service.dart';

void main() {
  group('AppUpdateService.isNewerVersion', () {
    test('Identical version and build returns false (no update prompt)', () {
      final result = AppUpdateService.isNewerVersion(
        currentVersion: '1.0.1',
        currentBuild: 5,
        latestVersion: '1.0.1',
        latestBuild: 5,
      );
      expect(result, isFalse);
    });

    test('Developer forgot to bump version in code/server returns false', () {
      final result = AppUpdateService.isNewerVersion(
        currentVersion: '1.0.1',
        currentBuild: 5,
        latestVersion: '1.0.1',
        latestBuild: 0,
      );
      expect(result, isFalse);
    });

    test('Server has older version returns false', () {
      final result = AppUpdateService.isNewerVersion(
        currentVersion: '1.0.1',
        currentBuild: 5,
        latestVersion: '1.0.0',
        latestBuild: 10,
      );
      expect(result, isFalse);
    });

    test('Server has higher patch version returns true', () {
      final result = AppUpdateService.isNewerVersion(
        currentVersion: '1.0.1',
        currentBuild: 5,
        latestVersion: '1.0.2',
        latestBuild: 5,
      );
      expect(result, isTrue);
    });

    test('Server has higher minor version returns true', () {
      final result = AppUpdateService.isNewerVersion(
        currentVersion: '1.0.1',
        currentBuild: 5,
        latestVersion: '1.1.0',
        latestBuild: 6,
      );
      expect(result, isTrue);
    });

    test('Server has higher build number with same version returns true', () {
      final result = AppUpdateService.isNewerVersion(
        currentVersion: '1.0.1',
        currentBuild: 5,
        latestVersion: '1.0.1',
        latestBuild: 6,
      );
      expect(result, isTrue);
    });

    test('Handles version with build tags and metadata safely', () {
      final result = AppUpdateService.isNewerVersion(
        currentVersion: '1.0.1+5',
        currentBuild: 5,
        latestVersion: '1.0.2+6',
        latestBuild: 6,
      );
      expect(result, isTrue);
    });
  });
}
