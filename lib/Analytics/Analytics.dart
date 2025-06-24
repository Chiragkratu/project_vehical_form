import 'package:flutter/material.dart';
import '../Custom_widgets/Custom_drawer.dart';
import '../Custom_widgets/Logout_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../Providers/vehicle_provider.dart';
import 'package:fl_chart/fl_chart.dart';

Future<String?> getFirebaseToken() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'firebase_token');
}

class Analytics extends StatefulWidget {
  @override
  _AnalyticsScreen createState() => _AnalyticsScreen();
}

class _AnalyticsScreen extends State<Analytics> {
  List<Map<String, dynamic>> list2 = [];
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> filteredData = [];
  String? VehicleName;
  int? Id;
  String? FuelType;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getPastrecords();
  }

  Future<void> getPastrecords() async {
    setState(() {
      isLoading = true;
    });
    
    final token = await getFirebaseToken();
    if (token == null) {
      print("No Firebase token found");
      setState(() {
        isLoading = false;
      });
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
      setState(() {
        list2.clear();
        for (var item in records) {
          list2.add(item);
        }
        // Filter data for selected vehicle if one is selected
        if (Id != null) {
          filterDataForSelectedVehicle();
        }
        isLoading = false;
      });

      print(list2);
    } catch (e) {
      print("Error fetching PastRecords : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterDataForSelectedVehicle() {
    if (Id != null) {
      setState(() {
        filteredData = list2.where((record) {
          // Assuming the vehicle_id field in the fuel records matches the vehicle id
          return record['vehicle_id'] == Id;
        }).toList();
        
        // Sort by date for better graph visualization
        filteredData.sort((a, b) {
          DateTime dateA = DateTime.parse(a['date'] ?? '');
          DateTime dateB = DateTime.parse(b['date'] ?? '');
          return dateA.compareTo(dateB);
        });
      });
    }
  }

  List<FlSpot> generateGraphData() {
    List<FlSpot> spots = [];
    
    for (int i = 0; i < filteredData.length; i++) {
      final record = filteredData[i];
      // Use the fuel amount or any other metric you want to plot
      double yValue = double.tryParse(record['fuel_quantity']?.toString() ?? '0') ?? 0;
      spots.add(FlSpot(i.toDouble(), yValue));
    }
    
    return spots;
  }

  Widget buildGraph() {
    if (filteredData.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Text(
            'No data available for selected vehicle',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'TimesNewRoman',
            ),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < filteredData.length) {
                    // Show date for bottom axis
                    String dateStr = filteredData[index]['date'] ??  '';
                    if (dateStr.isNotEmpty) {
                      DateTime date = DateTime.parse(dateStr);
                      return Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(fontSize: 10),
                      );
                    }
                  }
                  return Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: generateGraphData(),
              isCurved: true,
              color: Color.fromARGB(255, 70, 118, 91),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Color.fromARGB(255, 70, 118, 91).withOpacity(0.3),
              ),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    vehicles = context.watch<VehicleProvider>().vehicles;
    final themeColor = Color.fromARGB(255, 70, 118, 91);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'Analytics',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Vehicle Selection Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: vehicles.map((vehicle) {
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
                          FuelType = vehicle['fuel_type'];
                          // Filter data when vehicle is selected
                          filterDataForSelectedVehicle();
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
            
            // Selected Vehicle Info
            if (VehicleName != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Vehicle: $VehicleName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'TimesNewRoman',
                      ),
                    ),
                    Text(
                      'Fuel Type: $FuelType',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'TimesNewRoman',
                      ),
                    ),
                    Text(
                      'Records Found: ${filteredData.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'TimesNewRoman',
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 20),
            
            // Graph Section
            Expanded(
              child: Card(
                elevation: 4,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Fuel Offset Over Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'TimesNewRoman',
                        ),
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : buildGraph(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}