// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_usage/app_usage.dart';
import 'package:tvapp/accessibilityservice.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> globalData = {};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeService();
  runApp(const MyApp());
}

// Function to get the unique identifier
Future<String> getUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('user_id');
  if (userId == null) {
    userId = const Uuid().v4();
    await prefs.setString('user_id', userId);
  }
  return userId;
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Ensure Firebase is initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        service.setForegroundNotificationInfo(
          title: "My App Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    final usageData = await getUsageStats();
    debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    // Collect device data
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      globalData['device_model'] = androidInfo.model;
      globalData['device_id'] = androidInfo.id;
      globalData['network_type'] = 'WiFi'; // Example, fetch real data
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      globalData['device_model'] = iosInfo.utsname.machine;
      globalData['device_id'] = iosInfo.identifierForVendor;
      globalData['network_type'] = 'WiFi'; // Example, fetch real data
    }

    // Update other data fields
    globalData['current_date'] = DateTime.now().toIso8601String();
    globalData['app_usage'] = jsonEncode(usageData);
    // Add other data as necessary

    // Store data locally (example: using SharedPreferences or direct file storage)
    await storeDataLocally(globalData);
  });
}

// Example function to store data locally (you can customize this)
Future<void> storeDataLocally(Map<String, dynamic> data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> storedLogs = prefs.getStringList('user_logs') ?? [];
  storedLogs.add(jsonEncode(data));
  await prefs.setStringList('user_logs', storedLogs);
}

Future<List<Map<String, dynamic>>> getUsageStats() async {
  List<Map<String, dynamic>> usageStats = [];
  try {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(const Duration(hours: 24));
    List<AppUsageInfo> infoList =
        await AppUsage().getAppUsage(startDate, endDate);
    for (var info in infoList) {
      usageStats.add({
        'appName': info.appName,
        'packageName': info.packageName,
        'usage': info.usage.inMinutes,
        'startDate': info.startDate.toIso8601String(),
        'endDate': info.endDate.toIso8601String(),
      });
    }
  } on AppUsageException catch (exception) {
    debugPrint('$exception');
  }
  return usageStats;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: ThemeData.dark(), // Dark theme for better TV visibility
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizon Guard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Horizon Monitor'),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HorizonMonitor(),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: const Text('Horizon Logs'),
              onPressed: () async {
                String userid = await getUserId();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HorizonLogs(userid: userid, ip: ''), // Pass empty IP
                  ),
                );
              },
            ),
            ElevatedButton(
              child: const Text('Horizon Info'),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HorizonInfo(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HorizonMonitor extends StatefulWidget {
  const HorizonMonitor({super.key});

  @override
  HorizonMonitorState createState() => HorizonMonitorState();
}

class HorizonMonitorState extends State<HorizonMonitor> {
  List<AppUsageInfo> _infos = [];
  String deviceModel = '';
  String deviceId = '';
  String networkType = '';
  double latitude = 0.0;
  double longitude = 0.0;
  bool isConnected = false;
  String connectionType = '';

  @override
  void initState() {
    super.initState();

    fetchDeviceData();
    getUsageStats();
    // Add other initializations as needed
  }

  Future<void> fetchDeviceData() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      setState(() {
        deviceModel = androidInfo.model;
        deviceId = androidInfo.id;
        networkType = 'WiFi'; // Example, you should fetch real data
      });
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      setState(() {
        deviceModel = iosInfo.utsname.machine;
        deviceId = iosInfo.identifierForVendor!;
        networkType = 'WiFi'; // Example, you should fetch real data
      });
    }
  }

  Future<void> getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 24));
      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);
      setState(() => _infos = infoList);
      for (var info in infoList) {
        debugPrint(info.toString());
      }
    } on AppUsageException catch (exception) {
      debugPrint('$exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizon Monitor'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  title: Text('Device Model: $deviceModel'),
                  subtitle:
                      Text('Device ID: $deviceId\nNetwork Type: $networkType'),
                ),
              ),
              const Divider(),
              Card(
                child: ListTile(
                  title: const Text('Installed Apps'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _infos.map((info) {
                      return Text(
                          '${info.appName} - ${info.usage.inMinutes} minutes');
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),
              // Add other data fields here
              Card(
                child: ListTile(
                  title: const Text('Network Status'),
                  subtitle: Text(
                      'Connected: $isConnected\nConnection Type: $connectionType'),
                ),
              ),
              const Divider(),
              Card(
                child: ListTile(
                  title: const Text('GPS Coordinates'),
                  subtitle: Text('Latitude: $latitude\nLongitude: $longitude'),
                ),
              ),
              // Add other user activity fields here
            ],
          ),
        ),
      ),
    );
  }
}

class HorizonInfo extends StatefulWidget {
  const HorizonInfo({super.key});

  @override
  HorizonInfoState createState() => HorizonInfoState();
}

class HorizonInfoState extends State<HorizonInfo> {
  String deviceModel = '';
  String currentDate = '';

  @override
  void initState() {
    super.initState();
    fetchDeviceData();
    fetchCurrentDate();
  }

  Future<void> fetchDeviceData() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      setState(() {
        deviceModel = androidInfo.model;
      });
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      setState(() {
        deviceModel = iosInfo.utsname.machine;
      });
    }
  }

  void fetchCurrentDate() {
    setState(() {
      currentDate = DateTime.now().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizon Info'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  title: Text('Device: $deviceModel'),
                  subtitle: Text('Date: $currentDate'),
                ),
              ),
              const Divider(),
              Card(
                child: ListTile(
                  title: const Text('Foreground Mode'),
                  onTap: () {
                    // Add your foreground mode functionality here
                  },
                ),
              ),
              const Divider(),
              Card(
                child: ListTile(
                  title: const Text('Background Mode'),
                  onTap: () {
                    // Add your background mode functionality here
                  },
                ),
              ),
              const Divider(),
              Card(
                child: ListTile(
                  title: const Text('Stop Service'),
                  onTap: () {
                    // Add your stop service functionality here
                  },
                ),
              ),
              const Divider(),
              Card(
                child: ListTile(
                  title: const Text('Fetch Usage Data'),
                  onTap: () {
                    // Add your fetch usage data functionality here
                  },
                ),
              ),
              const Divider(),
              const Card(
                child: ListTile(
                  title: Text('App Usage Data'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [],
                  ),
                ),
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}
