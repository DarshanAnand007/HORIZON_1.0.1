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
      title: 'Horizon Guard',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 6,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          color: Colors.white,
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();  // Fetch data when the screen is first loaded
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("$e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizon Guard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,  // Trigger manual refresh when clicked
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(user['user_id'][0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(user['user_id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Last Updated: ${user['updated_time']}'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
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
