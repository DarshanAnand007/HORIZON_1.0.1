import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserLogsScreen extends StatefulWidget {
  const UserLogsScreen({super.key});

  @override
  UserLogsScreenState createState() => UserLogsScreenState();
}

class UserLogsScreenState extends State<UserLogsScreen> {
  List<dynamic> logs = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _timer =
        Timer.periodic(const Duration(seconds: 5), (timer) => _fetchLogs());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.0.106:4998/get_logs'));
      if (response.statusCode == 200) {
        setState(() {
          logs = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load logs');
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Logs'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(log['timestamp'] ?? 'N/A'),
              subtitle: Text(
                'Package name: ${log['package_name'] ?? 'N/A'}\n'
                'event_type: ${log['event_type'] ?? 'N/A'}\n'
                'Captured text: ${log['captured_text'] ?? 'N/A'}\n'
                'Subnode Info: ${log['subnodeinfo'] ?? 'N/A'}',
              ),
            ),
          );
        },
      ),
    );
  }
}
