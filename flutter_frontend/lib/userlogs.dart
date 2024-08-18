import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLogsScreen extends StatefulWidget {
  final String deviceId;

  const UserLogsScreen({super.key, required this.deviceId});

  @override
  UserLogsScreenState createState() => UserLogsScreenState();
}

class UserLogsScreenState extends State<UserLogsScreen> {
  List<dynamic> logs = [];
  List<dynamic> filteredLogs = [];
  Timer? _timer;
  TextEditingController searchController = TextEditingController();

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
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
      // Fetch logs for the specific user from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('accessibility_logs')
          .where('device', isEqualTo: widget.deviceId)
          .get();
      setState(() {
        logs = querySnapshot.docs.map((doc) => doc.data()).toList();
        filteredLogs = logs;
      });
    } catch (e) {
      debugPrint("$e");
    }
  }

  void _searchLogs(String query) {
    final results = logs.where((log) {
      final capturedText = log['captured_text']?.toLowerCase() ?? '';
      final subNodeText = log['sub_node_text']?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return capturedText.contains(searchQuery) ||
          subNodeText.contains(searchQuery);
    }).toList();

    setState(() {
      filteredLogs = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Logs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Logs',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchLogs(searchController.text);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
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
                      'Event type: ${log['event_type'] ?? 'N/A'}\n'
                      'Captured text: ${log['captured_text'] ?? 'N/A'}\n'
                      'Subnode Info: ${log['sub_node_text'] ?? 'N/A'}',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
