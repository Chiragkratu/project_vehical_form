import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // Create this next
import 'Register_screen.dart'; // Create this next
import 'package:project_vehical_form/Vehical_Registration/vehical_form.dart';
import 'Dashboard.dart';
import 'package:project_vehical_form/Vehical_Registration/vehicles_display.dart';
import 'Past_entries/Past_entries.dart';
import './Providers/vehicle_provider.dart';
import 'package:provider/provider.dart';
import 'Analytics/Analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => VehicleProvider())],
      child: MyApp(),
    ),
  );
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Token is not expired and user is signed in
      return Dashboard();
    } else {
      return LoginScreen();
    }
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Form App',
      debugShowCheckedModeBanner: false,
      home:AuthGate(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/vehicle': (context) => AddVehicleScreen(),
        '/dashboard': (context) => Dashboard(),
        '/vehicledisplay': (context) => Vehicle_Display(),
        '/pastentries': (context) => Past_entries(),
        '/analytics':(context) => Analytics(),
        // Replace with your actual home screen
      },
    );
  }
}
