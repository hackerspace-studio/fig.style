import 'package:auto_route/auto_route.dart';
import 'package:figstyle/utils/app_storage.dart';
import 'package:figstyle/utils/storage_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class NavigationHelper {
  static GlobalKey<NavigatorState> navigatorKey;

  static void clearSavedNotifiData() {
    appStorage.setString(StorageKeys.quoteIdNotification, '');
    appStorage.setString(StorageKeys.onOpenNotificationPath, '');
  }

  static void navigateNextFrame(
    PageRouteInfo pageRoute,
    BuildContext context,
  ) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      context.router.navigate(pageRoute);
    });
  }
}
