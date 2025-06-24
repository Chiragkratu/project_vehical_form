import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'Custom_widgets/Custom_drawer.dart';
import 'Custom_widgets/Logout_button.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import './Providers/vehicle_provider.dart';
import 'package:intl/intl.dart';

Future<String?> getFirebaseToken() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'firebase_token');
}

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? VehicleName;
  String? VehicleId;
  String? FuelType;
  double? FuelAmountLiters;
  bool? offset;
  List<List<String>> vehicles = [];

  final List<String> _fuelOptions = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          Provider.of<VehicleProvider>(context, listen: false).fetchVehicles(),
    );
    getVehicals();
  }

  Future<void> getVehicals() async {
    final token = await getFirebaseToken();
    if (token == null) {
      print("No Firebase token found");
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print("Failed to fetch vehicles: ${response.statusCode}");
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      print('yes');

      final vehicle = json.decode(response.body);
      List<List<String>> list1 = [];
      for (var item in vehicle) {
        if (item['retired_date'] == null) {
          list1.add([
            item['vehicle_name'].toString(),
            item['vehicle_id'].toString(),
            item['fuel_type'].toString(),
          ]);
        }
      }
      print("Vehicles fetched successfully: $list1");
      setState(() {
        vehicles = list1;
      });
    } catch (e) {
      print("Error fetching vehicles: $e");
    }
  }

  Future<void> submitFueldata() async {
    final token = await getFirebaseToken();
    if (token == null) {
      print("No Firebase token found");
      return;
    }
    DateTime today = DateTime.now();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/addfuel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'vehicle_id': VehicleId,
          'fuel_type': FuelType,
          'fuel_quantity': FuelAmountLiters,
          'date': DateFormat('yyyy-MM-dd').format(today),
          'offset': offset,
        }),
      );

      if (response.statusCode != 200) {
        print("Failed to submit fuel data: ${response.statusCode}");
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fuel data submitted successfully')),
        );
      }
    } catch (e) {
      print("Error submitting fuel data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color.fromARGB(255, 70, 118, 91);
    // SeaGreen

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'Dashboard',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontFamily: 'TimesNewRoman',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    ElevatedButton.icon(
                      icon: Icon(Icons.logout),
                      label: Text('Add Vehicle'),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/vehicle');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        vehicles.map((vehicle) {
                          final isSelected = VehicleName == vehicle[0];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: ChoiceChip(
                              label: Text(
                                vehicle[0],
                                style: TextStyle(fontFamily: 'TimesNewRoman'),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  VehicleName = vehicle[0];
                                  VehicleId = vehicle[1];
                                  FuelType = vehicle[2]; // default fuel type
                                });
                              },
                              selectedColor: themeColor,
                              backgroundColor: Colors.grey[200],
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),

                SizedBox(height: 20),
                if (FuelType != null) Text('Selected Fuel type: $FuelType'),
                SizedBox(height: 20),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Fuel Amount (Liters)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  onChanged:
                      (val) => setState(
                        () => FuelAmountLiters = double.tryParse(val),
                      ),
                ),

                SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: Icon(Icons.send, color: Colors.white),
                  label: Text(
                    'Offset Now',
                    style: TextStyle(
                      fontFamily: 'TimesNewRoman',
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    if (VehicleName == null ||
                        FuelType == null ||
                        FuelAmountLiters == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill all fields')),
                      );
                    } else {
                      offset = true;
                      Navigator.pushReplacementNamed(context, '/offset');
                      submitFueldata();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.send, color: Colors.white),
                  label: Text(
                    'Offset Later',
                    style: TextStyle(
                      fontFamily: 'TimesNewRoman',
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    if (VehicleName == null ||
                        FuelType == null ||
                        FuelAmountLiters == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill all fields')),
                      );
                    } else {
                      offset = false;
                      Navigator.pushReplacementNamed(context, '/offset');
                      submitFueldata();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
