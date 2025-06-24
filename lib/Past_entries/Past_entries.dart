import 'package:flutter/material.dart';
import '../Custom_widgets/Custom_drawer.dart';
import '../Custom_widgets/Logout_button.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../Providers/vehicle_provider.dart';

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

Future<void> savefuel(Map<String, dynamic> fuel) async {
  final token = await getFirebaseToken();
  try {
    final response = http.put(
      Uri.parse('http://10.0.2.2:8000/api/addfuel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(fuel),
    );

    print(response);
  } catch (e) {
    print('wrong data entered');
  }
}

class Past_entries extends StatefulWidget {
  @override
  Past_entries_screen createState() => Past_entries_screen();
}

class Past_entries_screen extends State<Past_entries> {
  final themeColor = Color.fromARGB(255, 70, 118, 91);
  String? VehicleName;
  int? Id;
  String? FuelType;
  List<Map<String, dynamic>> list1 = [];
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> list2 = [];
  List<String> allowedKeys = ['fuel_quantity', 'date'];

  final List<String> fuelOptions = [
    'Petrol',
    'Diesel',
    'Electric',
    'CNG',
    'Hybrid',
  ];

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<DataColumn> _buildcolumn() {
    if (list2.isEmpty) return [];

    List<String> keys =
        list2[0].keys
            .where((k) => allowedKeys.contains(k.toLowerCase()))
            .toList();
    return [
      ...keys.map((key) => DataColumn(label: Text(_beautifyLabel(key)))),
      DataColumn(label: Text('Edit')),
      DataColumn(label: Text('Delete')),
    ];
  }

  List<DataRow> _buildRows() {
    print(list2);
    return list2
        .asMap()
        .entries
        .where((entry) => entry.value['vehicle_id'] == Id) // filter here
        .map((entry) {
          Map<String, dynamic> vehicle = entry.value;
          int key = entry.key;
          List<DataCell> cells =
              vehicle.entries
                  .where((e) => allowedKeys.contains(e.key.toLowerCase()))
                  .map(
                    (e) => DataCell(Text(_beautifyLabel(e.value.toString()))),
                  )
                  .toList();

          cells.addAll([
            DataCell(
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () => {editfuel(key)},
              ),
            ),
            DataCell(
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => {_deletefuel(key)},
              ),
            ),
          ]);

          return DataRow(cells: cells);
        })
        .toList();
  }

  void editfuel(int key) async {
    String selectedFuel = list2[key]['fuel_type'] ?? fuelOptions[0];
    TextEditingController fuel_controllers = TextEditingController(
      text: list2[key]['fuel_quantity'].toString(),
    );
    TextEditingController date = TextEditingController(
      text: list2[key]['date']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Edit Fuel Consumption'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      allowedKeys.map((key) {
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
                        } else if (key == 'date') {
                          String displayDate =
                              date.text.isNotEmpty == true
                                  ? date.text
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
                              if (date.text.isNotEmpty == true) {
                                try {
                                  initialDate = DateTime.parse(date.text);
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
                                  date.text =
                                      picked.toIso8601String().split('T')[0];
                                });
                              }
                            },
                          );
                        } else {
                          return TextField(
                            controller: fuel_controllers,
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
                      for (var k in allowedKeys) {
                        if (k == 'fuel_type') {
                          list2[key][k] = selectedFuel;
                        } else if (k == 'fuel_quantity') {
                          list2[key][k] = fuel_controllers.text;
                        } else {
                          list2[key][k] = date.text;
                        }
                      }
                    });
                    savefuel(list2[key]);
                    Navigator.of(context).pop();
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

  void _deletefuel(int key) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Entry'),
            content: Text('Are you sure you want to delete this fuel entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => {
                      confirmdelete(list2[key]),
                      Navigator.of(ctx).pop(false),
                      setState(() {
                        list2.removeAt(key);
                      }),
                      
                    },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm) {
      print('1');
      setState(() {
        list2.removeAt(key);
      });
      print('Deleted list2 at index $key');
    }
  }

  void confirmdelete(Map<String, dynamic> fuel) async {
    final token = await getFirebaseToken();
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/addfuel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(fuel),
    );

    if (response.statusCode == 200) {
      _showMessage('Vehicle deleted succesfully');
    } else {
      _showMessage('error deleting vehicle ');
    }
  }

  Future<void> getPastrecords() async {
    final token = await getFirebaseToken();
    if (token == null) {
      print("No Firebase token found");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/addfuel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final records = await json.decode(response.body);
      for (var item in records) {
        list2.add(item);
      }

      print(list2);
    } catch (e) {
      print("Error fetching PastRecords : $e");
    }
  }


  void initState() {
    super.initState();
    // vehicles = context.watch<VehicleProvider>().vehicles;
    getPastrecords();
  }

  @override
  Widget build(BuildContext) {
    vehicles = context.watch<VehicleProvider>().vehicles;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    vehicles.map((vehicle) {
                      final isSelected = VehicleName == vehicle['vehicle_name'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            vehicle['vehicle_name'],
                            style: TextStyle(fontFamily: 'TimesNewRoman'),
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              VehicleName = vehicle['vehicle_name'];
                              Id = vehicle['id'];
                              FuelType =
                                  vehicle['fuel_type']; // default fuel type
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
            (list2.isEmpty)
                ? Center(child: Text('No data available'))
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _buildcolumn(),
                    rows: _buildRows(),
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all<Color>(
                      themeColor.withOpacity(0.1),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
