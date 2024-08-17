import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firebase Firestore
import 'package:tvapp/user_log.dart';
import 'export.dart'; // Import the export screen

class HorizonLogs extends StatefulWidget {
  const HorizonLogs({super.key, required this.userid, required String ip});
  final String userid;

  @override
  State<HorizonLogs> createState() => _HorizonLogsState();
}

class _HorizonLogsState extends State<HorizonLogs> {
  StreamSubscription<AccessibilityEvent>? _subscription;
  List<Map<String, dynamic>> logBatch = [];
  Map<String, dynamic>? lastLog;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedLogs = prefs.getStringList('accessibility_logs');
    if (storedLogs != null) {
      setState(() {
        logBatch = storedLogs
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  void handleAccessibilityStream() {
    if (_subscription?.isPaused ?? false) {
      _subscription?.resume();
      return;
    }
    _subscription =
        FlutterAccessibilityService.accessStream.listen((event) async {
      final newLog = logImportantDetails(event);

      if (newLog.isNotEmpty) {
        setState(() {
          logBatch.add(newLog);
        });
      }

      if (logBatch.length >= 100) {
        await _saveLogs();
        logBatch.clear(); // Clear the batch after saving
      }
    });
  }

  Map<String, dynamic> logImportantDetails(AccessibilityEvent event) {
    final packageName = event.packageName ?? "Unknown Package";
    final capturedText = event.text ?? "";
    final subNodeText = getSubNodeText(event.subNodes);

    // 1. Check for duplicate log
    if (lastLog != null && _isDuplicateLog(event, capturedText, subNodeText)) {
      return {}; // Return an empty map to indicate no log should be stored
    }

    // 2. Check if both subNodeText and capturedText are empty
    if ((capturedText.isEmpty || capturedText == 'null') &&
        subNodeText.isEmpty) {
      return {};
    }

    // 3. Check if package name is "com.example.tvapp"
    if (packageName == "com.example.tvapp") {
      log('scam');
      return {};
    }

    final logEntry = {
      'user_id': widget.userid,
      'package_name': packageName,
      'captured_text': capturedText,
      'timestamp': DateTime.now().toString(),
      'event_type': event.eventType.toString(),
      'map_id': event.mapId ?? "No mapId",
      'node_id': event.nodeId ?? "No nodeId",
      'sub_node_text': subNodeText,
    };

    lastLog = logEntry; // Update last log entry
    log(subNodeText);
    return logEntry;
  }

  bool _isDuplicateLog(
      AccessibilityEvent event, String capturedText, String subNodeText) {
    return lastLog != null &&
        lastLog!['package_name'] == event.packageName &&
        lastLog!['captured_text'] == capturedText &&
        lastLog!['event_type'] == event.eventType.toString() &&
        lastLog!['map_id'] == event.mapId &&
        lastLog!['node_id'] == event.nodeId &&
        lastLog!['sub_node_text'] == subNodeText;
  }

  String getSubNodeText(List<AccessibilityEvent>? subNodes) {
    if (subNodes == null || subNodes.isEmpty) {
      return "";
    }
    List<String> texts = [];
    for (var subNode in subNodes) {
      if (subNode.text != null &&
          subNode.text!.isNotEmpty &&
          subNode.text != 'null') {
        texts.add(subNode.text!);
      }
      final nestedSubNodeText = getSubNodeText(subNode.subNodes);
      if (nestedSubNodeText is! String && nestedSubNodeText.isNotEmpty) {
        texts.add(nestedSubNodeText);
      }
    }
    return texts.join(", ");
  }

  Future<void> _saveLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedLogs = logBatch.map((e) => jsonEncode(e)).toList();

    // Store logs locally
    await prefs.setStringList('accessibility_logs', storedLogs);

    // Send logs to Firebase Firestore only if subNodeText has changed
    CollectionReference logsCollection = FirebaseFirestore.instance.collection('accessibility_logs');

    for (var log in logBatch) {
      if (log['sub_node_text'] != lastLog?['sub_node_text']) {
        await logsCollection.add(log).catchError((error) {
          debugPrint('Failed to add log: $error');
        });
      }
    }
  }

  Future<bool> doAction(AccessibilityEvent node, NodeAction action,
      [dynamic argument]) async {
    return await FlutterAccessibilityService.performAction(
        node, action, argument);
  }

  void _clearLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs
        .remove('accessibility_logs'); // Clears the logs from SharedPreferences
    setState(() {
      logBatch.clear(); // Clears the logs from the local list
    });

    // Display a Snackbar with a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs cleared successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Horizon Logs'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await FlutterAccessibilityService
                            .requestAccessibilityPermission();
                      },
                      child: const Text("Request Permission"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () async {
                        final bool res = await FlutterAccessibilityService
                            .isAccessibilityPermissionEnabled();
                        log("Is enabled: $res");
                      },
                      child: const Text("Check Permission"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: handleAccessibilityStream,
                      child: const Text("Start Stream"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        _subscription?.cancel();
                      },
                      child: const Text("Stop Stream"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FlutterAccessibilityService.performGlobalAction(
                          GlobalAction.globalActionTakeScreenshot,
                        );
                      },
                      child: const Text("Take Screenshot"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final list = await FlutterAccessibilityService
                            .getSystemActions();
                        log('$list');
                      },
                      child: const Text("List GlobalActions"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserLogsScreen(logs: logBatch, onRefresh: () {  },), // Use local logs
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 40.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 10,
                      shadowColor: Colors.purpleAccent,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_stories, size: 24.0),
                        SizedBox(width: 10),
                        Text(
                          'View User Logs',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _clearLogs, // Calls the _clearLogs function
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 40.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 10,
                      shadowColor: Colors.purpleAccent,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, size: 24.0),
                        SizedBox(width: 10),
                        Text(
                          'Clear Logs',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExportScreen(), // Navigate to the ExportScreen
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 40.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 10,
                      shadowColor: Colors.greenAccent,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, size: 24.0),
                        SizedBox(width: 10),
                        Text(
                          'Export Data',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
