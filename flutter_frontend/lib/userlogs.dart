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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchLogs());
    searchController.addListener(() {
      _searchLogs(searchController.text);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
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
      final packageName = log['package_name']?.toLowerCase() ?? '';
      final eventType = log['event_type']?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return capturedText.contains(searchQuery) ||
          subNodeText.contains(searchQuery) ||
          packageName.contains(searchQuery) ||
          eventType.contains(searchQuery);
    }).toList();

    setState(() {
      filteredLogs = results;
    });
  }

  List<TextSpan> _highlightOccurrences(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final String lowerCaseText = text.toLowerCase();
    final String lowerCaseQuery = query.toLowerCase();

    int start = 0;
    int indexOfHighlight;
    while ((indexOfHighlight = lowerCaseText.indexOf(lowerCaseQuery, start)) != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow, // Background color for the highlighted text
          color: Colors.black, // Text color within the highlighted area
          fontWeight: FontWeight.bold,
        ),
      ));
      start = indexOfHighlight + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Logs'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Logs',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  _searchLogs(value);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  final searchQuery = searchController.text;

                  // Only highlight the tile if the search query is found
                  final highlightTile = log['captured_text']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false ||
                      log['sub_node_text']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false ||
                      log['package_name']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false ||
                      log['event_type']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;

                  return Container(
                     // No background color if no match
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(log['timestamp'] ?? 'N/A'),
                        subtitle: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [
                              const TextSpan(text: 'Package name: '),
                              ..._highlightOccurrences(log['package_name'] ?? 'N/A', searchQuery),
                              const TextSpan(text: '\nEvent type: '),
                              ..._highlightOccurrences(log['event_type'] ?? 'N/A', searchQuery),
                              const TextSpan(text: '\nCaptured text: '),
                              ..._highlightOccurrences(log['captured_text'] ?? 'N/A', searchQuery),
                              const TextSpan(text: '\nSubnode Info: '),
                              ..._highlightOccurrences(log['sub_node_text'] ?? 'N/A', searchQuery),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
