import 'package:flutter/foundation.dart';
import '../Custom_widgets/vehicle_service.dart';

class VehicleProvider with ChangeNotifier {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoaded = false;

  List<Map<String, dynamic>> get vehicles => _vehicles;
  bool get isLoaded => _isLoaded;

  Future<void> fetchVehicles() async {
    if (_isLoaded) return; // Avoid re-fetching
    _vehicles = await getVehiclesFromAPI();
    _isLoaded = true;
    notifyListeners();
  }

  Map<String, dynamic>? getVehicleById(String id) {
    return _vehicles.firstWhere((v) => v['id'] == id, orElse: () => {});
  }
}
