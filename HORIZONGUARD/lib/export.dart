// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  ExportScreenState createState() => ExportScreenState();
}

class ExportScreenState extends State<ExportScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _exportLogs() async {
    if (_startDate == null || _endDate == null || _startTime == null || _endTime == null) {
      setState(() {
        _errorMessage = "Please select both start and end dates with times.";
      });
      return;
    }

    DateTime startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    DateTime endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('accessibility_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startDateTime.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDateTime.toIso8601String())
          .orderBy('timestamp')
          .get();

      List<List<String>> csvData = [
        <String>['Timestamp', 'Package Name', 'Captured Text', 'Sub Node Text'],
        ...querySnapshot.docs.map((doc) => [
              doc['timestamp'] ?? '',
              doc['package_name'] ?? '',
              doc['captured_text'] ?? '',
              doc['sub_node_text'] ?? ''
            ])
      ];

      String csv = const ListToCsvConverter().convert(csvData);

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      String filePath = '$tempPath/logs.csv';
      File file = File(filePath);
      await file.writeAsString(csv);

      // Uploading to Google Drive
      await _uploadFileToDrive(filePath);
      _showSuccessMessage();
    } catch (error) {
      setState(() {
        _errorMessage = "Failed to export logs. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFileToDrive(String filePath) async {
    // Replace these with your OAuth client ID, client secret, and scopes
    const _clientId = "YOUR_CLIENT_ID";
    const _clientSecret = "YOUR_CLIENT_SECRET";
    final _scopes = [drive.DriveApi.driveFileScope];

    final authClient = await clientViaUserConsent(
      ClientId(_clientId, _clientSecret),
      _scopes,
      (url) {
        debugPrint("Please go to the following URL and grant access: $url");
      },
    );

    final driveApi = drive.DriveApi(authClient);
    final fileToUpload = File(filePath);
    final media = drive.Media(fileToUpload.openRead(), fileToUpload.lengthSync());

    var driveFile = drive.File();
    driveFile.name = "logs.csv";
    driveFile.parents = ["116uWIF-s-LUisBqSm9h1DwEHwItAKYxr"];  // The folder ID from your Drive link
    await driveApi.files.create(driveFile, uploadMedia: media);
    authClient.close();
  }

  void _showSuccessMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Export Successful"),
          content: const Text("The logs have been successfully exported to Google Drive."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Start Date and Time:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(_startDate != null
                        ? _startDate!.toLocal().toString().split(' ')[0]
                        : 'Select start date'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _selectTime(context, true),
                    child: Text(_startTime != null
                        ? _startTime!.format(context)
                        : 'Select start time'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Select End Date and Time:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(_endDate != null
                        ? _endDate!.toLocal().toString().split(' ')[0]
                        : 'Select end date'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _selectTime(context, false),
                    child: Text(_endTime != null
                        ? _endTime!.format(context)
                        : 'Select end time'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    )
                  : Container(),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _exportLogs,
                      child: const Text("Export Logs"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
