import 'package:flutter/material.dart';
import 'package:flutter_frontend/userlogs.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class UserDetailScreen extends StatelessWidget {
  final dynamic user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final appUsageMap = _parseAppUsageData(user['usage_info'] ?? []);
    final appUsageDetails = _getAppUsageDetails(user['usage_info'] ?? []);

    // Create a mapping from app names to their details
    final Map<String, String> appDetailsMap = {
      for (var detail in appUsageDetails) detail.split(': ')[0]: detail,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('User: ${user['device_id'] ?? 'N/A'}'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo('Device Model', user['device_model'] ?? 'N/A'),
              _buildUserInfo('Device ID', user['device_id'] ?? 'N/A'),
              _buildUserInfo('Network Type', user['network_type'] ?? 'N/A'),
              const SizedBox(height: 20),
              const Text('App Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _getSections(appUsageMap, appDetailsMap),
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              if (event is FlTapUpEvent && pieTouchResponse != null) {
                                final touchedSectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                final appName = _getAppNameByIndex(touchedSectionIndex, appUsageMap);
                                final appDetail = appDetailsMap[appName];
                                if (appDetail != null) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('App Usage Details'),
                                        content: Text(appDetail),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: appUsageMap.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.primaries[appUsageMap.keys.toList().indexOf(entry.key) % Colors.primaries.length],
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${entry.key}: ${entry.value.toStringAsFixed(1)}%'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildUserInfo('Created Time', user['timestamp'] ?? 'N/A'),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserLogsScreen(userId: user['device_id']),
                        ));
                  },
                  child: const Text('View Device Logs'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections(Map<String, double> appUsageMap, Map<String, String> appDetailsMap) {
    final List<PieChartSectionData> sections = [];
    appUsageMap.forEach((app, usage) {
      sections.add(PieChartSectionData(
        color: Colors.primaries[sections.length % Colors.primaries.length],
        value: usage,
        title: '',
        radius: 50,
      ));
    });
    return sections;
  }

  Map<String, double> _parseAppUsageData(List<dynamic> appUsageList) {
    final Map<String, double> appUsageMap = {};

    double totalUsage = 0;
    for (var app in appUsageList) {
      totalUsage += app['usage'];
    }
    for (var app in appUsageList) {
      appUsageMap[app['appName']] = (app['usage'] / totalUsage) * 100;
    }
    return appUsageMap;
  }

  List<String> _getAppUsageDetails(List<dynamic> appUsageList) {
    final List<String> appUsageDetails = [];
    for (var app in appUsageList) {
      appUsageDetails.add('${app['appName']}: ${app['usage']} minutes');
    }
    return appUsageDetails;
  }

  String _getAppNameByIndex(int index, Map<String, double> appUsageMap) {
    return appUsageMap.keys.toList()[index % appUsageMap.length];
  }
}
