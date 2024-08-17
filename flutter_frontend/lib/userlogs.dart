import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLogsScreen extends StatefulWidget {
  final String userId;

  const UserLogsScreen({super.key, required this.userId});

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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchLogs());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
      // Fetch logs for the specific user from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('accessibility_logs')
          .where('user_id', isEqualTo: widget.userId)
          .get();
      setState(() {
        logs = querySnapshot.docs.map((doc) => doc.data()).toList();
      });
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
                'Subnode Info: ${log['sub_node_text'] ?? 'N/A'}',
              ),
            ),
          );
        },
      ),
    );
  }
}
