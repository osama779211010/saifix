import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recharge_service.dart';
import '../models/recharge_offer.dart';
import '../models/recharge_transaction.dart';
import 'api_service.dart';

class S2DService {
  static const String baseUrl = ApiService.baseUrl;

  /// Get all available recharge services
  static Future<List<RechargeService>> getServices({String? type}) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('غير مسجل الدخول');

      String url = '${baseUrl}api/recharge/s2d/services/';
      if (type != null) {
        url += '?type=$type';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List servicesJson = data['data'] as List;
          return servicesJson
              .map((json) => RechargeService.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'فشل تحميل الخدمات');
        }
      } else {
        throw Exception('فشل تحميل الخدمات (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('خطأ في تحميل الخدمات: $e');
    }
  }

  /// Get offers for a specific service
  static Future<Map<String, dynamic>> getOffers(
    String serviceCode, {
    int? subscriberType,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('غير مسجل الدخول');

      String url = '${baseUrl}api/recharge/s2d/offers/$serviceCode/';
      if (subscriberType != null) {
        url += '?subscriber_type=$subscriberType';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final service = RechargeService.fromJson(data['service']);
          final List offersJson = data['offers'] as List;
          final offers =
              offersJson.map((json) => RechargeOffer.fromJson(json)).toList();

          return {'service': service, 'offers': offers};
        } else {
          throw Exception(data['message'] ?? 'فشل تحميل العروض');
        }
      } else if (response.statusCode == 404) {
        throw Exception('الخدمة غير موجودة');
      } else {
        throw Exception('فشل تحميل العروض (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('خطأ في تحميل العروض: $e');
    }
  }

  /// Process payment
  static Future<Map<String, dynamic>> processPayment({
    required String serviceCode,
    required String subscriberNumber,
    required double amount,
    String? offerId,
    String actionCode = '7100',
    int subscriberType = 1,
    String? remarks,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('غير مسجل الدخول');

      http.Response response;

      // الحالة الأولى (تفعيل باقة يمن موبايل): GET حصراً
      // الشرط: إذا كان serviceCode == '42103' (يمن موبايل) و تم تمرير offerId
      if (serviceCode == '42103' && offerId != null) {
        final queryParams = {
          'ac': '4002', // ac=4002 لتفعيل الباقات
          'sc': serviceCode,
          'sno': subscriberNumber,
          'sac': offerId, // SAC
          'mt': subscriberType.toString(),
        };

        if (amount > 0) {
          queryParams['amt'] = amount.toString();
        }

        if (remarks != null && remarks.isNotEmpty) {
          queryParams['rem'] = remarks;
        }

        final uri = Uri.parse(
          '${baseUrl}api/recharge/s2d/payment/',
        ).replace(queryParameters: queryParams);

        response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } else {
        // الحالة الثانية: POST (الوضع الحالي) للشحن العادي أو بقية الشركات
        final body = {
          'service_code': serviceCode,
          'subscriber_number': subscriberNumber,
          'amount': amount,
          'action_code': actionCode,
          'subscriber_type': subscriberType,
        };

        if (offerId != null) {
          body['offer_id'] = offerId;
        }
        if (remarks != null && remarks.isNotEmpty) {
          body['remarks'] = remarks;
        }

        response = await http.post(
          Uri.parse('${baseUrl}api/recharge/s2d/payment/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        );
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'فشل إتمام العملية');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في إتمام العملية: $e');
    }
  }

  /// Get transaction history
  static Future<List<RechargeTransaction>> getTransactionHistory() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('غير مسجل الدخول');

      final response = await http.get(
        Uri.parse('${baseUrl}api/recharge/s2d/history/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List transactionsJson = data['data'] as List;
          return transactionsJson
              .map((json) => RechargeTransaction.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'فشل تحميل السجل');
        }
      } else {
        throw Exception('فشل تحميل السجل (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('خطأ في تحميل السجل: $e');
    }
  }

  /// Client-side validation helper
  static ValidationResult validatePayment({
    required RechargeService service,
    required double amount,
    required int subscriberType,
    List<RechargeOffer>? availableOffers,
  }) {
    // Step 1: Validate amount against service rules
    final serviceValidation = service.validateAmount(amount, subscriberType);
    if (!serviceValidation.isValid) {
      return serviceValidation;
    }

    // Step 2: For PrePaid, check if amount matches an offer (unless service accepts any amount)
    if (subscriberType == 1 && !service.acceptsAnyAmountPrepaid) {
      if (availableOffers != null && availableOffers.isNotEmpty) {
        final matchingOffer = availableOffers.any(
          (offer) =>
              offer.amount == amount && offer.subscriberType == subscriberType,
        );

        if (!matchingOffer) {
          return ValidationResult(
            isValid: false,
            errorMessage:
                'المبلغ ${amount.toStringAsFixed(0)} غير متاح. يرجى اختيار من الباقات المتاحة',
          );
        }
      }
    }

    return ValidationResult(isValid: true);
  }
}
