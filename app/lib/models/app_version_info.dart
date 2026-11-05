class AppVersionInfo {
  final String platform;
  final String latestVersion;
  final int latestBuildNumber;
  final String minSupportedVersion;
  final int minSupportedBuildNumber;
  final String updateUrl;

  const AppVersionInfo({
    required this.platform,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minSupportedVersion,
    required this.minSupportedBuildNumber,
    required this.updateUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      platform: json['platform'] as String? ?? 'android',
      latestVersion: json['latestVersion'] as String? ?? '1.0.0',
      latestBuildNumber: (json['latestBuildNumber'] as num?)?.toInt() ?? 1,
      minSupportedVersion: json['minSupportedVersion'] as String? ?? '1.0.0',
      minSupportedBuildNumber:
          (json['minSupportedBuildNumber'] as num?)?.toInt() ?? 1,
      updateUrl:
          json['updateUrl'] as String? ??
          'https://play.google.com/store/apps/details?id=com.todocat.app',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'latestVersion': latestVersion,
      'latestBuildNumber': latestBuildNumber,
      'minSupportedVersion': minSupportedVersion,
      'minSupportedBuildNumber': minSupportedBuildNumber,
      'updateUrl': updateUrl,
    };
  }
}
