import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/firebase_options.dart';
import 'package:flutter_frontend/userdetail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User Activity Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  UserListScreenState createState() => UserListScreenState();
}

class UserListScreenState extends State<UserListScreen> {
  List<Map<String, dynamic>> users = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch data from Firestore
      final querySnapshot = await FirebaseFirestore.instance.collection('horizon_monitor_logs').get();
      setState(() {
        users = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'user_id': data['device_id'] ?? 'N/A',  // Use device_id if user_id is missing
            'updated_time': data['timestamp'] ?? 'N/A',
            ...data  // Include all other fields in the document
          };
        }).toList();
      });
    } catch (e) {
      debugPrint("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activity Monitor'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(user['user_id']),
              subtitle: Text('Last Updated: ${user['updated_time']}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailScreen(user: user),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
