import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../Custom_widgets/Custom_drawer.dart';
import '../Custom_widgets/Logout_button.dart';
import 'dart:convert';


Future<String?> getFirebaseToken() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'firebase_token');
}

String _beautifyLabel(String key) {
  return key
      .replaceAll('_', ' ') // replace underscores with spaces
      .split(' ') // split into words
      .map(
        (word) =>
            word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '',
      )
      .join(' '); // capitalize each word and rejoin
}

Future<void> editvehicle(Map<String, dynamic> vehicle) async {
  final token = await getFirebaseToken();
  try {
    final response = http.put(
      Uri.parse('http://10.0.2.2:8000/api/vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(vehicle),
    );

    print(response);
  } catch (e) {
    print('wrong data entered');
  }
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

class Vehicle_Display extends StatefulWidget {
  @override
  _VehicalDisplayScreen createState() => _VehicalDisplayScreen();
}

class _VehicalDisplayScreen extends State<Vehicle_Display> {
  final themeColor = Color.fromARGB(255, 70, 118, 91);
  List<Map<String, dynamic>> vehicles = [];
  List<String> allowedKeys = ['vehicle_name', 'fuel_type'];
  List<String> allowededitKeys = [
    'vehicle_type',
    'vehicle_name',
    'fuel_type',
    'vehicle_model',
    'vehicle_number',
    'acquire_date',
    'retired_date',
  ];
  
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }


  List<DataColumn> _buildColumns() {
    if (vehicles.isEmpty) return [];

    // Exclude 'id' or other unwanted keys
    List<String> keys =
        vehicles[0].keys
            .where((k) => allowedKeys.contains(k.toLowerCase()))
            .toList();

    return [
      ...keys.map((key) => DataColumn(label: Text(_beautifyLabel(key)))),
      DataColumn(label: Text('Edit')),
      DataColumn(label: Text('Delete')),
    ];
  }

  List<DataRow> _buildRows() {
    return vehicles.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> vehicle = entry.value;

      List<DataCell> cells =
          vehicle.entries
              .where(
                (e) => allowedKeys.contains(e.key.toLowerCase()),
              ) // skip 'id'
              .map((e) => DataCell(Text(_beautifyLabel(e.value.toString()))))
              .toList();

      cells.addAll([
        DataCell(
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _editVehicle(index),
          ),
        ),
        DataCell(
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteVehicle(index),
          ),
        ),
      ]);

      return DataRow(cells: cells);
    }).toList();
  }

  void _editVehicle(int index) {
    Map<String, dynamic> vehicle = vehicles[index];

    final List<String> fuelOptions = [
      'Petrol',
      'Diesel',
      'Electric',
      'CNG',
      'Hybrid',
    ];
    final List<String> vehicleTypeOptions = [
      'Two Wheeler',
      'Three Wheeler',
      'Four Wheeler',
      'Truck',
      'Bus',
      'Tractor',
      'Other',
    ];

    Map<String, TextEditingController> controllers = {};
    String selectedFuel = vehicle['fuel_type'] ?? fuelOptions[0];
    String selectedVehicleType =
        vehicle['vehicle_type'] ?? vehicleTypeOptions[0];

    // Make sure all editable fields are initialized
    for (var key in allowededitKeys) {
      if (key != 'fuel_type' && key != 'vehicle_type') {
        controllers[key] = TextEditingController(
          text: vehicle[key]?.toString() ?? '',
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Edit Vehicle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      allowededitKeys.map((key) {
                        if (key == 'fuel_type') {
                          return DropdownButtonFormField<String>(
                            value: selectedFuel,
                            decoration: InputDecoration(
                              labelText: _beautifyLabel(key),
                            ),
                            items:
                                fuelOptions.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => selectedFuel = value);
                              }
                            },
                          );
                        } else if (key == 'vehicle_type') {
                          return DropdownButtonFormField<String>(
                            value: selectedVehicleType,
                            decoration: InputDecoration(
                              labelText: _beautifyLabel(key),
                            ),
                            items:
                                vehicleTypeOptions.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedVehicleType = value,
                                );
                              }
                            },
                          );
                        } else if (key == 'acquire_date' ||
                            key == 'retired_date') {
                          String displayDate =
                              controllers[key]?.text.isNotEmpty == true
                                  ? controllers[key]!.text
                                  : 'Select date';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _beautifyLabel(key),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(displayDate),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () async {
                              DateTime initialDate = DateTime.now();
                              if (controllers[key]?.text.isNotEmpty == true) {
                                try {
                                  initialDate = DateTime.parse(
                                    controllers[key]!.text,
                                  );
                                } catch (_) {}
                              }

                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setModalState(() {
                                  controllers[key]?.text =
                                      picked.toIso8601String().split('T')[0];
                                });
                              }
                            },
                          );
                        } else {
                          return TextField(
                            controller: controllers[key],
                            decoration: InputDecoration(
                              labelText: _beautifyLabel(key),
                            ),
                          );
                        }
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (var key in allowededitKeys) {
                        if (key == 'fuel_type') {
                          vehicle[key] = selectedFuel;
                        } else if (key == 'vehicle_type') {
                          vehicle[key] = selectedVehicleType;
                        } else {
                          vehicle[key] =
                              controllers[key]?.text == ''
                                  ? null
                                  : controllers[key]?.text;
                        }
                      }
                    });
                    editvehicle(vehicle);
                    Navigator.of(context).pop();
                    print("Updated vehicle: ${vehicles[index]}");

                    // TODO: Send PUT request to backend if needed
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> Confirmdelete(int index) async {
    final token = await getFirebaseToken();
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(vehicles[index]),
    );
    getVehicals();
    if (response.statusCode == 200) {
      _showMessage('Vehicle deleted succesfully');
    }
    else{
      _showMessage('error deleting vehicle ');
    }
  }

  void _deleteVehicle(int index) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Vehicle'),
            content: Text('Are you sure you want to delete this vehicle?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => {Confirmdelete(index),Navigator.of(ctx).pop(false)},
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm) {
      setState(() {
        vehicles.removeAt(index);
      });
      print('Deleted vehicle at index $index');
    }
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
        return;
      }

      final vehicle = json.decode(response.body);
      List<Map<String, dynamic>> list1 = [];
      for (var item in vehicle) {
        list1.add(item);
      }

      print("Vehicles fetched successfully: $list1");
      setState(() {
        vehicles = list1;
      });
    } catch (e) {
      print("Error fetching vehicles: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getVehicals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'Vehicles',
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
        actions: [Logout_button(), SizedBox(width: 8)],
      ),
      drawer: CustomDrawer(themeColor: themeColor),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            vehicles.isEmpty
                ? Center(child: Text(
                  'No Vehicles Registered'
                ))
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _buildColumns(),
                    rows: _buildRows(),
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all<Color>(
                      themeColor.withOpacity(0.1),
                    ),
                  ),
                ),
      ),
    );
  }
}
