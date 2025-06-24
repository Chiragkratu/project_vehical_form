import 'package:flutter/material.dart';
import '../Custom_widgets/Custom_drawer.dart';
import '../Custom_widgets/Logout_button.dart';

class Offset extends StatefulWidget {
  @override
  OffsetScreen createState() => OffsetScreen();
}

class OffsetScreen extends State<Offset> {
  final themeColor = Color.fromARGB(255, 70, 118, 91);
  @override
  Widget build(BuildContext) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'Offset',
          style: TextStyle(
            fontFamily: 'TimesNewRoman',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Logout_button(),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
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
