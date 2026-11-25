import 'package:flutter/foundation.dart';
import '../models/court_model.dart';

class CourtProvider extends ChangeNotifier {
  List<CourtModel> _courts = const [];
  String? _selectedSport;
  bool _isLoading = false;
  String? _errorMessage;

  List<CourtModel> get courts => _courts;
  String? get selectedSport => _selectedSport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedSport(String? sport) {
    if (_selectedSport == sport) return;
    _selectedSport = sport;
    notifyListeners();
  }

  void updateCourts(List<CourtModel> items) {
    _courts = items;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
