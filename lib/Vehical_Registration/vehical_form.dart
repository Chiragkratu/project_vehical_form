import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';

Future<String?> getFirebaseToken() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'firebase_token');
}

Future<void> signOutUser() async {
  try {
    await FirebaseAuth.instance.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
    print("User signed out successfully");
  } catch (e) {
    print("Error signing out: $e");
  }
}

class AddVehicleScreen extends StatefulWidget {
  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleTypeController;
  final _vehicleModelController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _numberPlateController = TextEditingController();
  String? _fuelType;
  DateTime? _acquireDate;
  DateTime? _retireDate;

  final List<String> _fuelOptions = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid',
  ];
  final List<String> _vehicleTypeOptions = [
    'Two Wheeler',
    'Three Wheeler',
    'Four Wheeler',
    'Truck',
    'Bus',
    'Tractor',
    'Other',
  ];

  Future<DateTime?> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    return picked;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _fuelType != null) {
      final vehicleData = {
        'vehicle_type': _vehicleTypeController!,
        'vehicle_name': _vehicleNameController.text.trim(),
        'vehicle_model': _vehicleModelController.text.trim(),
        'vehicle_number': _numberPlateController.text.trim(),
        'fuel_type': _fuelType!,
        if (_acquireDate != null)
          'acquire_date': DateFormat('yyyy-MM-dd').format(_acquireDate!),
        if (_retireDate != null)
          'retired_date': DateFormat('yyyy-MM-dd').format(_retireDate!),
      };

      final token = await getFirebaseToken();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(vehicleData),
      );

      if (response.statusCode == 200) {
        _showMessage('Vehicle added successfully!');
      } else {
        _showMessage('Failed: ${response.statusCode}');
      }
    } else {
      _showMessage('Please fill all required fields.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: 'TimesNewRoman'),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _vehicleNameController.dispose();
    _numberPlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color.fromARGB(255, 70, 118, 91); // SeaGreen

    return Scaffold(
      backgroundColor: themeColor,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text('Add Vehicle', style: TextStyle(fontFamily: 'TimesNewRoman',color: Colors.white,fontWeight:  FontWeight.bold)),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            onPressed: () async {
              await signOutUser();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
          ),
          SizedBox(width: 8),
        ]
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: _vehicleTypeController,
                    decoration: _inputDecoration('Vehicle Type'),
                    items: _vehicleTypeOptions
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle(fontFamily: 'TimesNewRoman')),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _vehicleTypeController = val),
                    validator: (val) => val == null ? 'Select vehicle type' : null,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _vehicleNameController,
                    decoration: _inputDecoration('Vehicle Name'),
                    validator: (val) => val!.isEmpty ? 'Enter vehicle name' : null,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _vehicleModelController,
                    decoration: _inputDecoration('Vehicle Model (Optional)'),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _numberPlateController,
                    decoration: _inputDecoration('Number Plate (Optional)'),
                  ),
                  SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _fuelType,
                    decoration: _inputDecoration('Fuel Type'),
                    items: _fuelOptions
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle(fontFamily: 'TimesNewRoman')),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _fuelType = val),
                    validator: (val) => val == null ? 'Select fuel type' : null,
                  ),
                  SizedBox(height: 16),

                  ListTile(
                    title: Text(
                      _acquireDate == null
                          ? 'Pick Acquire Date (Optional)'
                          : 'Acquire Date: ${DateFormat('yyyy-MM-dd').format(_acquireDate!)}',
                      style: TextStyle(fontFamily: 'TimesNewRoman'),
                    ),
                    trailing: Icon(Icons.calendar_today, color: themeColor),
                    onTap: () async {
                      final date = await _pickDate(context);
                      if (date != null) setState(() => _acquireDate = date);
                    },
                  ),
                  SizedBox(height: 8),

                  ListTile(
                    title: Text(
                      _retireDate == null
                          ? 'Pick Retire Date (Optional)'
                          : 'Retire Date: ${DateFormat('yyyy-MM-dd').format(_retireDate!)}',
                      style: TextStyle(fontFamily: 'TimesNewRoman'),
                    ),
                    trailing: Icon(Icons.calendar_today, color: themeColor),
                    onTap: () async {
                      final date = await _pickDate(context);
                      if (date != null) setState(() => _retireDate = date);
                    },
                  ),

                  SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text('Save Vehicle', style: TextStyle(fontFamily: 'TimesNewRoman',color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/vehicle');
                    },
                    icon: Icon(Icons.directions_car, color: Colors.white),
                    label: Text('Add Another Vehicle', style: TextStyle(fontFamily: 'TimesNewRoman',color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    icon: Icon(Icons.dashboard, color: Colors.white),
                    label: Text('Go to Dashboard', style: TextStyle(fontFamily: 'TimesNewRoman',color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
