import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'balance_service.dart';
import '../helper/custom_print_helper.dart';

class AlzajilService {
  // Replace with your actual backend URL (e.g., 10.0.2.2 for Android emulator)
  static String get baseUrl => '${ApiService.baseUrl}api/recharge-payment';

  static const Duration _timeoutDuration = Duration(seconds: 120);

  Future<Map<String, dynamic>> sendPayment({
    required int actionCode,
    required int serviceCode,
    required double amount,
    required String subscriberNo,
    int? subscriberType,
    String? offerId,
    String? remarks,
    int? item,
    String? soi,
    double? cost,
    String? ref,
  }) async {
    final url = Uri.parse('$baseUrl/payment/');
    final body = {
      "ac": actionCode,
      "sc": serviceCode,
      "amt": amount,
      "sno": subscriberNo,
      if (subscriberType != null) "mt": subscriberType,
      if (offerId != null) "sac": offerId,
      if (remarks != null) "rem": remarks,
      if (item != null) "item": item,
      if (soi != null) "soi": soi,
      if (ref != null) "ref": ref,
    };

    try {
      final token = await ApiService.getToken();
      final jsonBody = jsonEncode(body);
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: utf8.encode(jsonBody),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      // customPrint("response of payment is $data");
      if (response.statusCode == 200) {
        balanceService.refreshBalance();
        return data;
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final errorData = data;
          errorMsg = errorData['MSG'] ?? errorData['msg'] ?? errorMsg;
          // If the serializer returned field-specific errors, join them
          if (errorData is Map && errorData.containsKey('amt')) {
            errorMsg = 'Amount Error: ${errorData['amt']}';
          }
        } catch (_) {}
        throw Exception('Failed to process payment: $errorMsg');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, dynamic>> checkBalance({
    required int serviceCode,
    required String subscriberNo,
    int? actionCode,
    int? item,
  }) async {
    String query = 'sc=$serviceCode&sno=$subscriberNo';
    if (actionCode != null) {
      query += '&ac=$actionCode';
    }
    if (item != null) {
      query += '&item=$item';
    }
    final url = Uri.parse('$baseUrl/subscriber-balance/?$query');
    try {
      final token = await ApiService.getToken();
      final response = await http
          .get(
            url,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to check balance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  /// Activate Yemen Mobile Package (AC 4002)
  /// Uses GET method with query string parameters
  Future<Map<String, dynamic>> activatePackage({
    required String serviceCode,
    required String subscriberNo,
    required String offerId,
    double? amount,
    String? ref,
  }) async {
    String query = 'ac=4002&sc=$serviceCode&sno=$subscriberNo&sac=$offerId';
    if (amount != null) query += '&amt=$amount';
    if (ref != null) query += '&ref=$ref';

    final url = Uri.parse('$baseUrl/package-activation/?$query');

    customPrint('📦 Activating package via GET: $url');

    try {
      final token = await ApiService.getToken();
      final response = await http
          .get(
            url,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      customPrint('📥 Package Activation Response: ${response.statusCode}');
      customPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        balanceService.refreshBalance();
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        // Try to extract MSG from the response body if it's JSON
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          final errorMsg =
              errorData['MSG'] ??
              errorData['msg'] ??
              'Error ${response.statusCode}';
          throw Exception('Failed to activate package: $errorMsg');
        } catch (_) {
          throw Exception('Failed to activate package: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error activating package: $e');
    }
  }

  Future<Map<String, dynamic>> getOffers({
    required int actionCode,
    required int serviceCode,
    required String subscriberNo,
  }) async {
    final url = Uri.parse(
      '$baseUrl/offers/?ac=$actionCode&sc=$serviceCode&sno=$subscriberNo',
    );
    try {
      final token = await ApiService.getToken();
      final response = await http
          .get(
            url,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await _saveOffers(serviceCode, subscriberNo, data);
        return data;
      } else {
        return await getCachedOffers(serviceCode, subscriberNo);
      }
    } catch (e) {
      return await getCachedOffers(serviceCode, subscriberNo);
    }
  }

  // --- Caching Logic ---

  Future<void> _saveOffers(
    int serviceCode,
    String subscriberNo,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_offers_${serviceCode}_$subscriberNo';
      await prefs.setString(key, jsonEncode(data));
      // Also store as general for this service if it's not specific
      await prefs.setString('last_offers_$serviceCode', jsonEncode(data));
    } catch (e) {
      customPrint('Error saving offers to cache: $e');
    }
  }

  Future<Map<String, dynamic>> getCachedOffers(
    int serviceCode,
    String subscriberNo,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_offers_${serviceCode}_$subscriberNo';
      String? data = prefs.getString(key);
      data ??= prefs.getString('last_offers_$serviceCode');

      if (data != null) {
        return jsonDecode(data);
      }
    } catch (e) {
      customPrint('Error reading offers from cache: $e');
    }
    return {'RC': 0, 'SD': [], 'msg': 'بيانات مخزنة مسبقاً (وضع الأوفلاين)'};
  }

  static const String financialsBaseUrl = '${ApiService.baseUrl}api/financials';

  Future<Map<String, dynamic>> p2pTransfer({
    required String senderPhone,
    required String recipientPhone,
    required double amount,
    String currency = 'YER',
  }) async {
    final url = Uri.parse('$financialsBaseUrl/transfers/p2p/');
    final body = {
      "sender_phone": senderPhone,
      "recipient_phone": recipientPhone,
      "amount": amount,
      "currency": currency,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: utf8.encode(jsonEncode(body)),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, dynamic>> atmWithdraw({
    required String phone,
    required double amount,
    required String bank,
  }) async {
    final url = Uri.parse('$financialsBaseUrl/withdraw/atm/');
    final body = {"phone": phone, "amount": amount, "bank": bank};

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: utf8.encode(jsonEncode(body)),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}
