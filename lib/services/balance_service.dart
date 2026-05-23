import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class BalanceService extends ChangeNotifier {
  static final BalanceService _instance = BalanceService._internal();
  factory BalanceService() => _instance;
  BalanceService._internal() {
    _loadState();
  }

  Map<String, String> _balances = {'YER': '0.00', 'USD': '0.00', 'SAR': '0.00'};
  bool _isHidden = true;
  String _selectedCurrency = 'YER';

  Map<String, String> get balances => _balances;
  bool get isHidden => _isHidden;
  String get selectedCurrency => _selectedCurrency;

  String get currentBalance => _balances[_selectedCurrency] ?? '0.00';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isHidden = prefs.getBool('balance_hidden') ?? true;
    _selectedCurrency = prefs.getString('selected_balance_currency') ?? 'YER';

    final cached = prefs.getString('cached_balances');
    if (cached != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cached);
        _balances = decoded.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      } catch (e) {
        customPrint("Error loading cached balances: $e");
      }
    }
    notifyListeners();
  }

  Future<void> toggleVisibility() async {
    _isHidden = !_isHidden;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_hidden', _isHidden);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _selectedCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_balance_currency', _selectedCurrency);
    notifyListeners();
  }

  Future<void> refreshBalance({bool forceRefresh = false}) async {
    try {
      final Map<String, dynamic> data = await ApiService.getBalances(
        forceRefresh: forceRefresh,
      );
      _balances = data.map((key, value) => MapEntry(key, value.toString()));
      notifyListeners();
    } catch (e) {
      // Keep cached balances
    }
  }

  void updateBalances(Map<String, dynamic> newBalances) {
    _balances = newBalances.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    notifyListeners();
  }
}

final balanceService = BalanceService();
