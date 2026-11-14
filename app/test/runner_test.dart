import 'package:flutter_test/flutter_test.dart';
import 'package:todocat/models/runner.dart';

void main() {
  group('RunnerType', () {
    test('cat frame counts and asset paths', () {
      const runner = RunnerType.cat;
      expect(runner.id, equals('cat'));
      expect(runner.displayName, equals('Cat'));
      expect(runner.runFrameCount, equals(7));
      expect(runner.sleepFrameCount, equals(6));
      expect(
        runner.assetPath(isWhite: false, isSleeping: false, frame: 0),
        equals('assets/runners/cat/run/0.png'),
      );
      expect(
        runner.assetPath(isWhite: true, isSleeping: true, frame: 5),
        equals('assets/runners/cat_white/sleep/5.png'),
      );
    });

    test('bunny frame counts and asset paths', () {
      const runner = RunnerType.bunny;
      expect(runner.id, equals('bunny'));
      expect(runner.displayName, equals('Bunny'));
      expect(runner.runFrameCount, equals(8));
      expect(runner.sleepFrameCount, equals(7));
      expect(runner.runFramesFor(isWhite: false), equals(8));
      expect(runner.sleepFramesFor(isWhite: false), equals(7));
      expect(runner.runFramesFor(isWhite: true), equals(5));
      expect(runner.sleepFramesFor(isWhite: true), equals(5));
      expect(
        runner.assetPath(isWhite: false, isSleeping: false, frame: 7),
        equals('assets/runners/bunny/run/7.png'),
      );
      expect(
        runner.assetPath(isWhite: true, isSleeping: true, frame: 6),
        equals('assets/runners/bunny_white/sleep/1.png'),
      );
      expect(
        runner.assetPath(isWhite: true, isSleeping: false, frame: 4),
        equals('assets/runners/bunny_white/run/4.png'),
      );
    });

    test('axolotl frame counts and asset paths', () {
      const runner = RunnerType.axolotl;
      expect(runner.id, equals('axolotl'));
      expect(runner.displayName, equals('Axolotl'));
      expect(runner.runFrameCount, equals(9));
      expect(runner.sleepFrameCount, equals(7));
      expect(runner.runFramesFor(isWhite: false), equals(9));
      expect(runner.sleepFramesFor(isWhite: false), equals(7));
      expect(runner.runFramesFor(isWhite: true), equals(9));
      expect(runner.sleepFramesFor(isWhite: true), equals(7));
      expect(
        runner.assetPath(isWhite: false, isSleeping: false, frame: 8),
        equals('assets/runners/axolotl/run/8.png'),
      );
      expect(
        runner.assetPath(isWhite: true, isSleeping: true, frame: 6),
        equals('assets/runners/axolotl_white/sleep/6.png'),
      );
    });

    test('fromString parsing', () {
      expect(RunnerType.fromString('bunny'), equals(RunnerType.bunny));
      expect(RunnerType.fromString('axolotl'), equals(RunnerType.axolotl));
      expect(RunnerType.fromString('cat'), equals(RunnerType.cat));
      expect(RunnerType.fromString(null), equals(RunnerType.cat));
      expect(RunnerType.fromString('unknown'), equals(RunnerType.cat));
    });
  });
}
