# توثيق API استلام الحوالات (صيفي كاش) 🚀

هذا الملف مخصص لمطور التطبيق لشرح كيفية تنفيذ دورة استلام الحوالات: **الاستعلام** ثم **التأكيد**.

---

## 1. شاشة الاستعلام عن حوالة (Enquiry)

تُستخدم هذه الواجهة للتأكد من وجود الحوالة وجلب بياناتها (المبلغ، العملة، اسم المرسل) قبل السماح للمستخدم باستلامها.

- **Endpoint:** `POST /api/SaifiCash/wallet/receive-enquiry/`
- **Headers:** 
    - `Authorization: Bearer <YOUR_TOKEN>`
    - `Content-Type: application/json`

### مثال الطلب (Request JSON):
```json
{
    "saifi_rmt_no": "123456789" // رقم الحوالة المدخل من قبل المستخدم
}
```

### استجابة النجاح (Success Response):
```json
{
    "status": "success",
    "message": "تم جلب بيانات الحوالة بنجاح.",
    "data": {
        "rcv_rqst_no": "RCV-20230501-ABC1", // رقم الطلب (مهم جداً لعملية التأكيد)
        "rmt_amt": "100.00",
        "rmt_ccy": "USD",
        "sndr_name": "أحمد محمد علي",
        "bnf_name": "خالد عمر حسن"
    }
}
```

### استجابة الفشل (Error Response):
```json
{
    "status": "error",
    "message": "فشل جلب البيانات.",
    "error_detail": "5006 - رقم الحوالة غير صحيح أو تم استلامها مسبقاً"
}
```

---

## 2. شاشة تأكيد الاستلام (Confirm Receipt)

تُستخدم هذه الواجهة لإتمام عملية الاستلام نهائياً. سيقوم النظام تلقائياً بسحب بيانات هوية المستخدم الموثقة (KYC) لإرسالها كإثبات استلام.

- **Endpoint:** `POST /api/SaifiCash/wallet/confirm-receipt/`
- **Headers:** 
    - `Authorization: Bearer <YOUR_TOKEN>`
    - `Content-Type: application/json`

### مثال الطلب (Request JSON):
```json
{
    "saifi_rmt_no": "123456789",
    "rcv_rqst_no": "RCV-20230501-ABC1" // يجب إرسال رقم الطلب الذي عاد من مرحلة الاستعلام
}
```

### استجابة النجاح (Success Response):
```json
{
    "status": "success",
    "message": "تم تأكيد استلام الحوالة بنجاح، وتم قيد المبلغ في حسابك.",
    "data": {
        "saifi_rmt_no": "123456789",
        "rsp_code": "1"
    }
}
```

### استجابة الفشل (Error Response):
```json
{
    "status": "error",
    "message": "فشل تأكيد الاستلام.",
    "error_detail": "خطأ من نظام صيفي: يجب تحديث بيانات الهوية"
}
```

---

## 3. مثال الربط في Flutter (Dart)

يمكنك استخدام هذا الكود المبسط لإجراء الطلبات:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SaifiCashService {
  final String baseUrl = "https://your-domain.com/api/SaifiCash";
  final String token;

  SaifiCashService(this.token);

  // 1. وظيفة الاستعلام
  Future<Map<String, dynamic>> enquireRemittance(String rmtNo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/receive-enquiry/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'saifi_rmt_no': rmtNo}),
    );

    return jsonDecode(response.body);
  }

  // 2. وظيفة التأكيد النهائي
  Future<Map<String, dynamic>> confirmReceipt(String rmtNo, String rcvRqstNo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/confirm-receipt/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'saifi_rmt_no': rmtNo,
        'rcv_rqst_no': rcvRqstNo,
      }),
    );

    return jsonDecode(response.body);
  }
}
```

### ملاحظات هامة للمطور:
1. **بيانات الهوية**: لا داعي لإرسال بيانات اسم المستخدم أو رقم هويته في الـ Body، السيرفر يقوم بجلبها آلياً من بروفايله الموثق لضمان الأمان.
2. **رقم الطلب**: تأكد من حفظ قيمة `rcv_rqst_no` من استجابة الاستعلام لتمريرها في خطوة التأكيد.
3. **الأخطاء**: في حالة الفشل، اعرض للمستخدم قيمة `error_detail` فهي تحتوي على رسالة الخطأ القادمة من نظام صيفي مباشرة.
