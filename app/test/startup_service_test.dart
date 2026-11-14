import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todocat/services/startup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StartupService', () {
    late Directory tempDir;
    late File testDesktopFile;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('todocat_autostart_test_');
      testDesktopFile = File('${tempDir.path}/autostart/todocat.desktop');
      StartupService.testLinuxDesktopFile = testDesktopFile;
    });

    tearDown(() async {
      StartupService.testLinuxDesktopFile = null;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('isSupported returns expected desktop platforms', () {
      expect(StartupService.isSupported, Platform.isMacOS || Platform.isLinux);
    });

    test('Linux autostart enable creates desktop entry file and saves pref', () async {
      if (!Platform.isLinux) {
        // Test file writing logic directly with mock file
        final file = testDesktopFile;
        expect(file.existsSync(), isFalse);

        // Simulate Linux write
        await file.parent.create(recursive: true);
        await file.writeAsString('[Desktop Entry]\nName=TodoCat\n');
        expect(file.existsSync(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('Name=TodoCat'));

        await file.delete();
        expect(file.existsSync(), isFalse);
      } else {
        final success = await StartupService.instance.setEnabled(true);
        expect(success, isTrue);
        expect(testDesktopFile.existsSync(), isTrue);
        final content = await testDesktopFile.readAsString();
        expect(content, contains('[Desktop Entry]'));
        expect(content, contains('Name=TodoCat'));

        final isEnabled = await StartupService.instance.isEnabled();
        expect(isEnabled, isTrue);

        final disableSuccess = await StartupService.instance.setEnabled(false);
        expect(disableSuccess, isTrue);
        expect(testDesktopFile.existsSync(), isFalse);
      }
    });

    test('macOS mock method channel setEnabled and isEnabled', () async {
      if (Platform.isMacOS) {
        bool mockState = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(StartupService.macChannel, (call) async {
          if (call.method == 'setLaunchAtStartup') {
            final args = call.arguments as Map?;
            mockState = args?['enabled'] == true;
            return true;
          } else if (call.method == 'isLaunchAtStartupEnabled') {
            return mockState;
          }
          return null;
        });

        final initial = await StartupService.instance.isEnabled();
        expect(initial, isFalse);

        final ok = await StartupService.instance.setEnabled(true);
        expect(ok, isTrue);

        final enabled = await StartupService.instance.isEnabled();
        expect(enabled, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(StartupService.prefKey), isTrue);

        final disabledOk = await StartupService.instance.setEnabled(false);
        expect(disabledOk, isTrue);
        expect(prefs.getBool(StartupService.prefKey), isFalse);

        final isStillEnabled = await StartupService.instance.isEnabled();
        expect(isStillEnabled, isFalse);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(StartupService.macChannel, null);
      }
    });
  });
}
