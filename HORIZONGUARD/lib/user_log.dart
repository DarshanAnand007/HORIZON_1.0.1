import 'package:flutter/material.dart';

class UserLogsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> logs;

  const UserLogsScreen({super.key, required this.logs});

  @override
  _UserLogsScreenState createState() => _UserLogsScreenState();
}

class _UserLogsScreenState extends State<UserLogsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.logs.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: widget.logs.length,
              itemBuilder: (context, index) {
                final log = widget.logs[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text('Timestamp: ${log['timestamp'] ?? 'N/A'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Package Name: ${log['package_name'] ?? 'N/A'}'),
                        Text('Captured Text: ${log['captured_text'] ?? 'N/A'}'),
                        Text('Event Type: ${log['event_type'] ?? 'N/A'}'),
                        Text('Map ID: ${log['map_id'] ?? 'N/A'}'),
                        Text('Node ID: ${log['node_id'] ?? 'N/A'}'),
                        Text('Sub Node Text: ${log['sub_node_text'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                'No logs found.',
                style: TextStyle(fontSize: 18.0, color: Colors.grey),
              ),
            ),
    );
  }
}
