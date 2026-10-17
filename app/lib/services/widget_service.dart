import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _androidWidgetProvider = 'TodoCatWidgetProvider';

  static Future<void> updateWidget({
    required int pendingCount,
    required int totalCount,
    required int speedPercent,
    required String speedMessage,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('pending_count', pendingCount);
      await HomeWidget.saveWidgetData<int>('total_count', totalCount);
      await HomeWidget.saveWidgetData<int>('speed_percent', speedPercent);
      await HomeWidget.saveWidgetData<String>('speed_message', speedMessage);

      await HomeWidget.updateWidget(
        name: _androidWidgetProvider,
        androidName: _androidWidgetProvider,
      );
    } catch (_) {
      // Best-effort widget update
    }
  }

  static Future<bool> requestPinWidget() async {
    try {
      final isSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isSupported == true) {
        await HomeWidget.requestPinWidget(
          name: _androidWidgetProvider,
          androidName: _androidWidgetProvider,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
