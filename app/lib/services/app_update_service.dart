import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version_info.dart';
import '../presentation/widgets/app_update_dialog.dart';
import '../presentation/widgets/app_toast.dart';
import 'api_service.dart';

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  AppUpdateService._internal();

  static const String _remindLaterDateKey = 'app_update_remind_later_date';
  bool _isDialogShowing = false;

  /// Checks if an app update is available.
  /// If [force] is false, suppresses prompting if the user selected "Remind Me Later" today.
  Future<void> checkAndShowUpdate(
    BuildContext context, {
    bool force = false,
  }) async {
    if (_isDialogShowing) return;

    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();

    if (!force) {
      final lastRemindedDate = prefs.getString(_remindLaterDateKey);
      if (lastRemindedDate == todayKey) {
        return;
      }
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final AppVersionInfo? versionInfo = await ApiService().fetchAppVersion();
      if (versionInfo == null || !context.mounted) return;

      final hasUpdate = isNewerVersion(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        latestVersion: versionInfo.latestVersion,
        latestBuild: versionInfo.latestBuildNumber,
      );

      if (hasUpdate) {
        _isDialogShowing = true;
        if (!context.mounted) {
          _isDialogShowing = false;
          return;
        }

        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogCtx) => AppUpdateDialog(
            versionInfo: versionInfo,
            onRemindLater: () async {
              Navigator.of(dialogCtx).pop();
              await prefs.setString(_remindLaterDateKey, todayKey);
            },
            onUpdate: () async {
              Navigator.of(dialogCtx).pop();
              final uri = Uri.parse(versionInfo.updateUrl);
              try {
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched && context.mounted) {
                  AppToast.show(context, 'Could not open store link',
                      isError: true);
                }
              } catch (_) {
                if (context.mounted) {
                  AppToast.show(context, 'Could not open store link',
                      isError: true);
                }
              }
            },
          ),
        );
        _isDialogShowing = false;
      }
    } catch (e) {
      _isDialogShowing = false;
      debugPrint('[AppUpdateService] update check error: $e');
    }
  }

  /// Compares local and remote versions. Returns true ONLY if remote is strictly greater.
  /// If versions are identical or remote is older (e.g. forgot to bump in code), returns false.
  static bool isNewerVersion({
    required String currentVersion,
    required int currentBuild,
    required String latestVersion,
    required int latestBuild,
  }) {
    final currentParts = _parseVersion(currentVersion);
    final latestParts = _parseVersion(latestVersion);

    final maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    if (maxLength > 0) {
      for (int i = 0; i < maxLength; i++) {
        final currentSeg = i < currentParts.length ? currentParts[i] : 0;
        final latestSeg = i < latestParts.length ? latestParts[i] : 0;

        if (latestSeg > currentSeg) {
          return true;
        } else if (latestSeg < currentSeg) {
          return false;
        }
      }
    }

    // If semantic versions match, check build number if both are available
    if (latestBuild > 0 && currentBuild > 0) {
      return latestBuild > currentBuild;
    }

    return false;
  }

  static List<int> _parseVersion(String version) {
    final clean = version.split('+').first.split('-').first.trim();
    if (clean.isEmpty) return [];
    return clean
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
