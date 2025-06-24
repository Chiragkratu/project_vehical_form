// lib/services/vehicle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


Future<String?> getFirebaseToken() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'firebase_token');
}


Future<List<Map<String, dynamic>>> getVehiclesFromAPI() async {
  final token = await getFirebaseToken();

  if (token == null) {
    print("No Firebase token found");
    return [];
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
      return [];
    }

    final List<dynamic> vehicle = json.decode(response.body);
    List<Map<String, dynamic>> list1 = [];

    for (var item in vehicle) {
      list1.add(item as Map<String, dynamic>);
    }

    print("Vehicles fetched successfully: $list1");
    return list1;
  } catch (e) {
    print("Error fetching vehicles: $e");
    return [];
  }
}
