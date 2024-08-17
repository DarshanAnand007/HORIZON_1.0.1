import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/userdetail.dart';
import 'package:http/http.dart' as http;

void main() {
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
  List<dynamic> users = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer =
        Timer.periodic(const Duration(seconds: 5), (timer) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.0.106:4998/get_all_users'));
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load user data');
      }
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
              title: Text(user['user_id'] ?? 'N/A'),
              subtitle: Text('Last Updated: ${user['updated_time'] ?? 'N/A'}'),
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
