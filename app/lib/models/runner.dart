enum RunnerType {
  cat,
  bunny,
  axolotl;

  String get id => name;

  String get displayName {
    switch (this) {
      case RunnerType.cat:
        return 'Cat';
      case RunnerType.bunny:
        return 'Bunny';
      case RunnerType.axolotl:
        return 'Axolotl';
    }
  }

  int get runFrameCount {
    switch (this) {
      case RunnerType.cat:
        return 7;
      case RunnerType.bunny:
        return 8;
      case RunnerType.axolotl:
        return 9;
    }
  }

  int get sleepFrameCount {
    switch (this) {
      case RunnerType.cat:
        return 6;
      case RunnerType.bunny:
        return 7;
      case RunnerType.axolotl:
        return 7;
    }
  }

  int runFramesFor({required bool isWhite}) {
    if (this == RunnerType.bunny && isWhite) return 5;
    return runFrameCount;
  }

  int sleepFramesFor({required bool isWhite}) {
    if (this == RunnerType.bunny && isWhite) return 5;
    return sleepFrameCount;
  }

  String assetPath({
    required bool isWhite,
    required bool isSleeping,
    required int frame,
  }) {
    final state = isSleeping ? 'sleep' : 'run';
    if (this == RunnerType.bunny && isWhite) {
      final safeFrame = frame % 5;
      return 'assets/runners/bunny_white/$state/$safeFrame.png';
    }
    final folder = '$name${isWhite ? '_white' : ''}';
    return 'assets/runners/$folder/$state/$frame.png';
  }

  String previewAssetPath({required bool isWhite}) {
    final folder = '$name${isWhite ? '_white' : ''}';
    return 'assets/runners/$folder/run/0.png';
  }

  static RunnerType fromString(String? val) {
    if (val == 'bunny') return RunnerType.bunny;
    if (val == 'axolotl') return RunnerType.axolotl;
    return RunnerType.cat;
  }
}
