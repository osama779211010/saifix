# دليل مبرمج Flutter — Transaction Preview API

## نقطة الاتصال
```
POST /api/general/transaction-preview/
Authorization: Bearer <token>
Content-Type: application/json
```

---

## أنواع العمليات المدعومة (transaction_type)

| الكود | الاسم |
|-------|-------|
| `P2P_TRANSFER_SEND` | تحويل إلى مشترك |
| `P2P_TRANSFER_RECV` | استلام من مشترك |
| `CURRENCY_EXCHANGE` | مصارفة بين العملات |
| `REMIT_SEND` | إرسال حوالة |
| `REMIT_SEND_SAIFI` | إرسال حوالة صيفي كاش |
| `REMIT_RECV` | استلام حوالة |
| `REMIT_RECV_SAIFI` | استلام حوالة صيفي كاش |
| `RECHARGE` | شحن رصيد |
| `BILL_PAYMENT` | سداد فواتير |
| `PURCHASE_SERVICE` | شراء خدمات/ألعاب |
| `POS_PAYMENT` | دفع مشتريات (نقطة مبيعات) |
| `AGENT_WITHDRAW_REQ` | سحب نقدي عبر وكيل |
| `AGENT_DEPOSIT_TO_USER` | إيداع لمشترك عبر الوكيل |
| `AGENT_DEPOSIT_TO_POS` | إيداع لنقطة تجارية |
| `COLLECTION_PAY` | دفع إلى قسمك |
| `SUB_WALLET_DEPOSIT` | إيداع لفرد عائلة |
| `PIGGYBANK_DEPOSIT` | دفع إلى حصالة |

---

## البيانات المُرسَلة (Request Body)

| الحقل | النوع | إلزامي | الوصف |
|-------|-------|--------|-------|
| `transaction_type` | String | ✅ | كود نوع العملية |
| `amount` | Number | ✅ | المبلغ (موجب) |
| `currency` | String | ✅ | `YER` أو `USD` أو `SAR` |
| `target_identifier` | String | حسب العملية | رقم هاتف / رقم POS |
| `user_type` | String | ❌ | اختياري — يُستنتج تلقائياً |

### متى تُرسِل `target_identifier`؟
| نوع العملية | ما تُرسِله |
|-------------|-----------|
| تحويل P2P | رقم هاتف المستلم أو رقم المحفظة |
| دفع POS | رقم نقطة المبيعات (7 أرقام) |
| سحب عبر وكيل | رقم POS الفرع أو رقم هاتفه |
| إيداع عبر وكيل | رقم هاتف العميل أو رقم محفظته |
| شحن/سداد/حوالة | اختياري |

---

## البيانات المُستلَمة (Response)

### هيكل الرد الموحّد
```json
{
  "status": "allowed | rejected",
  "rejection_reason": null,
  "operation_type": "P2P_TRANSFER_SEND",
  "operation_name": "تحويل إلى مشترك (إرسال)",
  "target": { ... },
  "financials": { ... },
  "limits": { ... }
}
```

### كائن `target` عند البحث عن عميل محفظة
```json
{
  "type": "WALLET_USER",
  "name": "أكرم علي العبدلي",
  "username": "771234567",
  "wallet_id": 1000023,
  "is_active": true,
  "is_verified": true
}
```

### كائن `target` عند البحث عن فرع وكيل / POS
```json
{
  "type": "AGENT_BRANCH",
  "name": "فرع الحسبة - شركة الصيفي",
  "branch_name": "فرع الحسبة",
  "agent_name": "شركة الصيفي",
  "pos_number": "1234567",
  "governorate": "أمانة العاصمة",
  "area": "الحسبة",
  "is_active": true
}
```

### كائن `financials`
```json
{
  "amount": 5000.0,
  "fee": 100.0,
  "total_deduction": 5100.0,
  "currency": "YER",
  "fee_breakdown": {
    "agent_share": 30.0,
    "company_share": 70.0
  }
}
```

### كائن `limits`
```json
{
  "has_rule": true,
  "is_allowed": true,
  "message": "العملية ضمن السقوف المسموحة",
  "per_transaction": { "min": 100.0, "max": 500000.0 },
  "daily": {
    "used_amount": 15000.0,
    "used_count": 3,
    "max_amount": 100000.0,
    "max_count": 10,
    "remaining_amount": 85000.0,
    "remaining_count": 7
  },
  "monthly": {
    "used_amount": 80000.0,
    "used_count": 15,
    "max_amount": 500000.0,
    "max_count": 50,
    "remaining_amount": 420000.0,
    "remaining_count": 35
  }
}
```
> **ملاحظة:** `remaining_amount: null` = غير محدود (لا سقف).

---

## أكواد HTTP

| الكود | المعنى | الإجراء |
|-------|--------|---------|
| `200` | مسموح — اعرض الفاتورة | أكمل تنفيذ العملية |
| `422` | مرفوض (تجاوز سقف أو وجهة غير موجودة) | اعرض `rejection_reason` |
| `400` | بيانات ناقصة أو خاطئة | اعرض `errors` |
| `401` | غير مسجّل دخول | اطلب تسجيل الدخول |

---

## أمثلة عملية

---

### مثال 1 — تحويل P2P ناجح

**Request:**
```json
{
  "transaction_type": "P2P_TRANSFER_SEND",
  "amount": 5000,
  "currency": "YER",
  "target_identifier": "771234567"
}
```
**Response 200:**
```json
{
  "status": "allowed",
  "rejection_reason": null,
  "operation_type": "P2P_TRANSFER_SEND",
  "operation_name": "تحويل إلى مشترك (إرسال)",
  "target": {
    "type": "WALLET_USER",
    "name": "محمد أحمد السقاف",
    "username": "771234567",
    "wallet_id": 1000045,
    "is_active": true,
    "is_verified": true
  },
  "financials": {
    "amount": 5000.0,
    "fee": 50.0,
    "total_deduction": 5050.0,
    "currency": "YER",
    "fee_breakdown": {"agent_share": 0.0, "company_share": 50.0}
  },
  "limits": {
    "has_rule": true,
    "is_allowed": true,
    "message": "العملية ضمن السقوف المسموحة",
    "per_transaction": {"min": 100.0, "max": 500000.0},
    "daily": {"used_amount": 10000.0, "used_count": 2, "max_amount": 200000.0, "max_count": 20, "remaining_amount": 190000.0, "remaining_count": 18},
    "monthly": {"used_amount": 50000.0, "used_count": 10, "max_amount": 1000000.0, "max_count": 100, "remaining_amount": 950000.0, "remaining_count": 90}
  }
}
```

---

### مثال 2 — تحويل يتجاوز السقف اليومي

**Request:**
```json
{
  "transaction_type": "P2P_TRANSFER_SEND",
  "amount": 195000,
  "currency": "YER",
  "target_identifier": "771234567"
}
```
**Response 422:**
```json
{
  "status": "rejected",
  "rejection_reason": "هذه العملية ستتجاوز السقف اليومي (200,000 ر.ي). المتبقي اليوم: 190,000 ر.ي",
  "operation_type": "P2P_TRANSFER_SEND",
  "operation_name": "تحويل إلى مشترك (إرسال)",
  "target": {"type": "WALLET_USER", "name": "محمد أحمد السقاف", "username": "771234567", "wallet_id": 1000045, "is_active": true, "is_verified": true},
  "financials": {"amount": 195000.0, "fee": 1950.0, "total_deduction": 196950.0, "currency": "YER", "fee_breakdown": {"agent_share": 0.0, "company_share": 1950.0}},
  "limits": {
    "has_rule": true,
    "is_allowed": false,
    "message": "هذه العملية ستتجاوز السقف اليومي (200,000 ر.ي). المتبقي اليوم: 190,000 ر.ي",
    "per_transaction": {"min": 100.0, "max": 500000.0},
    "daily": {"used_amount": 10000.0, "used_count": 2, "max_amount": 200000.0, "max_count": 20, "remaining_amount": 190000.0, "remaining_count": 18},
    "monthly": {"used_amount": 50000.0, "used_count": 10, "max_amount": 1000000.0, "max_count": 100, "remaining_amount": 950000.0, "remaining_count": 90}
  }
}
```

---

### مثال 3 — دفع نقطة مبيعات POS

**Request:**
```json
{
  "transaction_type": "POS_PAYMENT",
  "amount": 12000,
  "currency": "YER",
  "target_identifier": "1234567"
}
```
**Response 200:**
```json
{
  "status": "allowed",
  "rejection_reason": null,
  "operation_type": "POS_PAYMENT",
  "operation_name": "دفع مشتريات (نقطة مبيعات)",
  "target": {
    "type": "AGENT_BRANCH",
    "name": "سوبر ماركت السعيدة - وكالة الأمين",
    "branch_name": "سوبر ماركت السعيدة",
    "agent_name": "وكالة الأمين",
    "pos_number": "1234567",
    "governorate": "أمانة العاصمة",
    "area": "شميلة",
    "is_active": true
  },
  "financials": {"amount": 12000.0, "fee": 0.0, "total_deduction": 12000.0, "currency": "YER", "fee_breakdown": {"agent_share": 0.0, "company_share": 0.0}},
  "limits": {"has_rule": false, "is_allowed": true, "message": "لا توجد قيود مسجلة على هذه العملية", "per_transaction": {"min": 0, "max": 0}, "daily": {}, "monthly": {}}
}
```

---

### مثال 4 — سحب نقدي عبر وكيل

**Request:**
```json
{
  "transaction_type": "AGENT_WITHDRAW_REQ",
  "amount": 50000,
  "currency": "YER",
  "target_identifier": "1234567"
}
```
**Response 200:**
```json
{
  "status": "allowed",
  "rejection_reason": null,
  "operation_type": "AGENT_WITHDRAW_REQ",
  "operation_name": "سحب نقدي عبر وكيل (طلب)",
  "target": {
    "type": "AGENT_BRANCH",
    "name": "فرع الحسبة - شركة الصيفي",
    "branch_name": "فرع الحسبة",
    "agent_name": "شركة الصيفي",
    "pos_number": "1234567",
    "governorate": "أمانة العاصمة",
    "area": "الحسبة",
    "is_active": true
  },
  "financials": {"amount": 50000.0, "fee": 500.0, "total_deduction": 50500.0, "currency": "YER", "fee_breakdown": {"agent_share": 150.0, "company_share": 350.0}},
  "limits": {
    "has_rule": true,
    "is_allowed": true,
    "message": "العملية ضمن السقوف المسموحة",
    "per_transaction": {"min": 1000.0, "max": 200000.0},
    "daily": {"used_amount": 0.0, "used_count": 0, "max_amount": 300000.0, "max_count": 5, "remaining_amount": 300000.0, "remaining_count": 5},
    "monthly": {"used_amount": 100000.0, "used_count": 3, "max_amount": 1000000.0, "max_count": 30, "remaining_amount": 900000.0, "remaining_count": 27}
  }
}
```

---

### مثال 5 — شحن رصيد (بدون target)

**Request:**
```json
{
  "transaction_type": "RECHARGE",
  "amount": 3000,
  "currency": "YER"
}
```
**Response 200:**
```json
{
  "status": "allowed",
  "rejection_reason": null,
  "operation_type": "RECHARGE",
  "operation_name": "شحن رصيد",
  "target": null,
  "financials": {"amount": 3000.0, "fee": 30.0, "total_deduction": 3030.0, "currency": "YER", "fee_breakdown": {"agent_share": 10.0, "company_share": 20.0}},
  "limits": {
    "has_rule": true,
    "is_allowed": true,
    "message": "العملية ضمن السقوف المسموحة",
    "per_transaction": {"min": 500.0, "max": 50000.0},
    "daily": {"used_amount": 6000.0, "used_count": 2, "max_amount": 50000.0, "max_count": 10, "remaining_amount": 44000.0, "remaining_count": 8},
    "monthly": {"used_amount": 20000.0, "used_count": 8, "max_amount": 200000.0, "max_count": 50, "remaining_amount": 180000.0, "remaining_count": 42}
  }
}
```

---

### مثال 6 — تحويل بالدولار

**Request:**
```json
{
  "transaction_type": "P2P_TRANSFER_SEND",
  "amount": 100,
  "currency": "USD",
  "target_identifier": "771234567"
}
```
**Response 200:**
```json
{
  "status": "allowed",
  "rejection_reason": null,
  "operation_type": "P2P_TRANSFER_SEND",
  "operation_name": "تحويل إلى مشترك (إرسال)",
  "target": {"type": "WALLET_USER", "name": "محمد أحمد السقاف", "username": "771234567", "wallet_id": 1000045, "is_active": true, "is_verified": true},
  "financials": {"amount": 100.0, "fee": 1.0, "total_deduction": 101.0, "currency": "USD", "fee_breakdown": {"agent_share": 0.0, "company_share": 1.0}},
  "limits": {
    "has_rule": true,
    "is_allowed": true,
    "message": "العملية ضمن السقوف المسموحة",
    "per_transaction": {"min": 1.0, "max": 5000.0},
    "daily": {"used_amount": 0.0, "used_count": 0, "max_amount": 2000.0, "max_count": 10, "remaining_amount": 2000.0, "remaining_count": 10},
    "monthly": {"used_amount": 500.0, "used_count": 5, "max_amount": 10000.0, "max_count": 50, "remaining_amount": 9500.0, "remaining_count": 45}
  }
}
```

---

### مثال 7 — مستخدم غير موجود

**Request:**
```json
{
  "transaction_type": "P2P_TRANSFER_SEND",
  "amount": 5000,
  "currency": "YER",
  "target_identifier": "779999999"
}
```
**Response 422:**
```json
{
  "status": "rejected",
  "rejection_reason": "لم يتم العثور على مستخدم بالمعرِّف: 779999999",
  "operation_type": "P2P_TRANSFER_SEND",
  "operation_name": "تحويل إلى مشترك (إرسال)",
  "target": null,
  "financials": null,
  "limits": null
}
```

---

### مثال 8 — بيانات ناقصة

**Request:**
```json
{
  "transaction_type": "P2P_TRANSFER_SEND",
  "currency": "YER"
}
```
**Response 400:**
```json
{
  "errors": {
    "amount": "هذا الحقل مطلوب"
  }
}
```

---

### مثال 9 — مبلغ أقل من الحد الأدنى

**Request:**
```json
{
  "transaction_type": "AGENT_WITHDRAW_REQ",
  "amount": 500,
  "currency": "YER",
  "target_identifier": "1234567"
}
```
**Response 422:**
```json
{
  "status": "rejected",
  "rejection_reason": "المبلغ 500 YER أقل من الحد الأدنى للعملية الواحدة (1000 YER)",
  "operation_type": "AGENT_WITHDRAW_REQ",
  "operation_name": "سحب نقدي عبر وكيل (طلب)",
  "target": {"type": "AGENT_BRANCH", "name": "فرع الحسبة - شركة الصيفي", "branch_name": "فرع الحسبة", "agent_name": "شركة الصيفي", "pos_number": "1234567", "governorate": "أمانة العاصمة", "area": "الحسبة", "is_active": true},
  "financials": {"amount": 500.0, "fee": 5.0, "total_deduction": 505.0, "currency": "YER", "fee_breakdown": {"agent_share": 1.5, "company_share": 3.5}},
  "limits": {
    "has_rule": true,
    "is_allowed": false,
    "message": "المبلغ 500 YER أقل من الحد الأدنى للعملية الواحدة (1000 YER)",
    "per_transaction": {"min": 1000.0, "max": 200000.0},
    "daily": {"used_amount": 0.0, "used_count": 0, "max_amount": 300000.0, "max_count": 5, "remaining_amount": 300000.0, "remaining_count": 5},
    "monthly": {"used_amount": 0.0, "used_count": 0, "max_amount": 1000000.0, "max_count": 30, "remaining_amount": 1000000.0, "remaining_count": 30}
  }
}
```

---

## تكامل Flutter (Dart)

```dart
Future<Map<String, dynamic>> previewTransaction({
  required String transactionType,
  required double amount,
  required String currency,
  String? targetIdentifier,
}) async {
  final response = await dio.post(
    '/api/general/transaction-preview/',
    data: {
      'transaction_type': transactionType,
      'amount': amount,
      'currency': currency,
      if (targetIdentifier != null) 'target_identifier': targetIdentifier,
    },
  );

  if (response.statusCode == 200 || response.statusCode == 422) {
    return response.data;
  } else if (response.statusCode == 400) {
    throw ValidationException(response.data['errors']);
  }
  throw Exception('خطأ غير متوقع');
}

// الاستخدام في الـ UI
void onAmountConfirmed() async {
  final preview = await previewTransaction(
    transactionType: 'P2P_TRANSFER_SEND',
    amount: 5000,
    currency: 'YER',
    targetIdentifier: recipientPhone,
  );

  if (preview['status'] == 'allowed') {
    final targetName    = preview['target']?['name'] ?? '';
    final fee           = preview['financials']['fee'];
    final totalDeduct   = preview['financials']['total_deduction'];
    final dailyLeft     = preview['limits']['daily']['remaining_amount']; // null = unlimited
    showConfirmSheet(targetName, fee, totalDeduct, dailyLeft);
  } else {
    showError(preview['rejection_reason']);
  }
}
```

---

## نصائح مهمة للمبرمج

| # | النصيحة |
|---|---------|
| 1 | **استدعِ المعاينة قبل كل عملية** — لا تنفِّذ مباشرةً |
| 2 | **اعرض شاشة تأكيد** تحتوي: اسم المستلم + المبلغ + العمولة + الإجمالي |
| 3 | **`remaining_amount: null`** = غير محدود، لا تعرض رقماً |
| 4 | **`fee: 0`** = بدون رسوم، أخفِ سطر العمولة |
| 5 | **HTTP 422** ليس خطأ شبكة — تعامل معه كـ business rule |
| 6 | البحث يدعم: رقم الهاتف أو `wallet_id` أو الرقم البديل |
| 7 | `user_type` يُستنتج تلقائياً من التوكن — لا حاجة لإرساله |
