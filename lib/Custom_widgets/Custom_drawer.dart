import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final Color themeColor;

  const CustomDrawer({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: themeColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Dashboard'),
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: Icon(Icons.analytics),
            title: Text('Analytics'),
            onTap: () => Navigator.pushReplacementNamed(context, '/analytics'), 
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Past Entries'),
            onTap: () => Navigator.pushReplacementNamed(context, '/pastentries'),
          ),
          ListTile(
            leading: Icon(Icons.car_rental),
            title: Text('Vehicles'),
            onTap: () => Navigator.pushReplacementNamed(context, '/vehicledisplay'),
          ),
        ],
      ),
    );
  }
}
