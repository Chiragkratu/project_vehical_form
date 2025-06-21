import 'package:flutter/material.dart';
import '../Custom_widgets/Custom_drawer.dart';
import '../Custom_widgets/Logout_button.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> getFirebaseToken() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'firebase_token');
}

Future<void> Getpastrecords() async {
  final token = await getFirebaseToken();
  if (token == null) {
    print("No Firebase token found");
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/pastrecords'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final records = response.body;
    print(records);
    
  } catch (e) {
    print("Error fetching PastRecords : $e");
  }
}

class Past_entries extends StatefulWidget {
  @override
  Past_entries_screen createState() => Past_entries_screen();
}

class Past_entries_screen extends State<Past_entries> {
  final themeColor = Color.fromARGB(255, 70, 118, 91);

  
  @override
  Widget build(BuildContext) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'Past Entries',
          style: TextStyle(
            fontFamily: 'TimesNewRoman',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          Logout_button(),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              print("Profile tapped");
            },
          ),
        ],
      ),
      drawer: CustomDrawer(themeColor: themeColor),
    );
  }
}
