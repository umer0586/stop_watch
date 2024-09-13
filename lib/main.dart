import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'service/stopwatch_service.dart' as stop_watch_service;

void main() {
  // Initialize port for communication between TaskHandler and UI.
  FlutterForegroundTask.initCommunicationPort();
  debugPrint("main()");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stop Watch Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Stop Watch'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _time = "00:00:00";
  var _isStopWatchRunning = false;

  // data from background task
  void _onReceiveTaskData(dynamic data) {

    if (data is Map<String, dynamic>) {

      if (data.containsKey("time")) {
        setState(() {
          _time = data["time"];
        });
      }

      if (data.containsKey("isStopWatchRunning")) {
        // on setState when there is a change
        if(_isStopWatchRunning != data["isStopWatchRunning"]) {
          setState(() {
            _isStopWatchRunning = data["isStopWatchRunning"];
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Add a callback to receive data sent from the TaskHandler.
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request permissions and initialize the service.
      _requestPermissions();
      _initService();
    });
  }

  @override
  void dispose() {
    // Remove a callback to receive data sent from the TaskHandler.
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_time.toString(), style: const TextStyle(fontSize: 30),),
                )),

            const SizedBox(height: 20,),

            if (!_isStopWatchRunning)
              IconButton(
                iconSize: 60,
                  color: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.play_circle),
                  onPressed: ()  {
                    _startService();
                  })
            else
              IconButton(
              iconSize: 60,
              color: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.stop_circle),
                  onPressed: () {
                    _stopService();
                  })
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
      // onNotificationPressed function to be called.
      //
      // When the notification is pressed while permission is denied,
      // the onNotificationPressed function is not called and the app opens.
      //
      // If you do not use the onNotificationPressed or launchApp function,
      // you do not need to write this code.
/*      if (!await FlutterForegroundTask.canDrawOverlays) {
        // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
        await FlutterForegroundTask.openSystemAlertWindowSettings();
      }*/

      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  Future<void> _initService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'stop_watch_channel',
        channelName: 'Stop watch channel',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<ServiceRequestResult> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Stop Watch',
        notificationText: 'Stop watch is Running',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: "stop_id", text: 'stop'),
        ],
        callback: stop_watch_service.startCallback,
      );

    }

  }

  Future<ServiceRequestResult> _stopService() async {
    return FlutterForegroundTask.stopService();
  }
}
