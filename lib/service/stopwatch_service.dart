
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  final stopWatchTimer = StopWatchTimer(
      mode: StopWatchMode.countUp
  );
  @override
  void onStart(DateTime timestamp) {
    debugPrint('onStart');
    stopWatchTimer.onStartTimer();

    stopWatchTimer.rawTime.listen((raw){
      FlutterForegroundTask.sendDataToMain({
        "time" : StopWatchTimer.getDisplayTime(raw),
        "isStopWatchRunning" : stopWatchTimer.isRunning
      });
    });

  }

  // Called every [ForegroundTaskOptions.interval] milliseconds.
  @override
  void onRepeatEvent(DateTime timestamp) {

  }

  // Called when the task is destroyed.
  @override
  void onDestroy(DateTime timestamp) {
    debugPrint('onDestroy');
    stopWatchTimer.onStopTimer();
    stopWatchTimer.dispose();

    FlutterForegroundTask.sendDataToMain({
      "isStopWatchRunning" : stopWatchTimer.isRunning
    });
  }

  // Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  @override
  void onReceiveData(Object data) {
    debugPrint('onReceiveData: $data');
  }

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    debugPrint('onNotificationButtonPressed: $id');
    if(id == "stop_id"){
      debugPrint("stopping service");
      FlutterForegroundTask.stopService();
    }
  }

  // Called when the notification itself is pressed.
  //
  // AOS: "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted
  // for this function to be called.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    debugPrint('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  //
  // AOS: only work Android 14+
  // iOS: only work iOS 10+
  @override
  void onNotificationDismissed() {
    debugPrint('onNotificationDismissed');
  }
}