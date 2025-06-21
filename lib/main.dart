import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; // Create this next
import 'Register_screen.dart'; // Create this next
import 'package:project_vehical_form/Vehical_Registration/vehical_form.dart'; 
import 'Dashboard.dart';
import 'package:project_vehical_form/Vehical_Registration/vehicles_display.dart';
import 'Past_entries/Past_entries.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Form App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/vehicle':(context) => AddVehicleScreen(),
        '/dashboard':(context)=> Dashboard(),
        '/vehicledisplay':(context)=> Vehicle_Display(),
        '/pastentries':(context) => Past_entries()
        // Replace with your actual home screen
      },
    );
  }
}