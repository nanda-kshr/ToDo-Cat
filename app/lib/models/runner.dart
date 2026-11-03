enum RunnerType {
  cat,
  bunny;

  String get id => name;

  String get displayName {
    switch (this) {
      case RunnerType.cat:
        return 'Cat';
      case RunnerType.bunny:
        return 'Bunny';
    }
  }

  int get runFrameCount {
    switch (this) {
      case RunnerType.cat:
        return 7;
      case RunnerType.bunny:
        return 5;
    }
  }

  int get sleepFrameCount {
    switch (this) {
      case RunnerType.cat:
        return 6;
      case RunnerType.bunny:
        return 5;
    }
  }

  String assetPath({
    required bool isWhite,
    required bool isSleeping,
    required int frame,
  }) {
    final folder = '$name${isWhite ? '_white' : ''}';
    final state = isSleeping ? 'sleep' : 'run';
    return 'assets/runners/$folder/$state/$frame.png';
  }

  String previewAssetPath({required bool isWhite}) {
    final folder = '$name${isWhite ? '_white' : ''}';
    return 'assets/runners/$folder/run/0.png';
  }

  static RunnerType fromString(String? val) {
    if (val == 'bunny') return RunnerType.bunny;
    return RunnerType.cat;
  }
}
