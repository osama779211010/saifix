# 📄 توثيق API — طلبات استلام الحوالات
**Receipt Requests API Documentation**

> **Base URL:** `http://<server-ip>:8000/api/remittances/`
> **المصادقة:** يجب إرسال رمز JWT في كل طلب عبر Header:
> ```
> Authorization: Bearer <access_token>
> ```
> **ملاحظة:** هذه الـ APIs خاصة بمستخدمي التطبيق (WalletUser) فقط.

---

## 1. إرسال طلب استلام حوالة جديد

**`POST /api/remittances/receipt-requests/`**

يستخدمه المستخدم لطلب تسجيل استلام حوالة واردة له. يقوم النظام بتعيين رقم عملية فريد وتحديد حالة الطلب كـ "معلق" تلقائياً.

### 📤 Request Body (JSON)

| الحقل | النوع | مطلوب | الوصف |
|-------|-------|--------|-------|
| `remittance_number` | `string` (max 30) | ✅ نعم | رقم الحوالة الوارد من شبكة الحوالات |
| `code_name_network` | `string` (max 100) | ✅ نعم | رمز أو اسم الشبكة (مثلاً: `NajmNet`, `AlImtiaz`) |
| `remittance_type` | `string` | ✅ نعم | نوع الحوالة: `LOCAL` (محلية) أو `INTERNATIONAL` (دولية) |
| `amount` | `decimal` | ❌ اختياري | مبلغ الحوالة المتوقع |
| `notes` | `string` | ❌ اختياري | أي ملاحظات إضافية من المستخدم |

**مثال على الطلب:**
```json
{
    "remittance_number": "TRX-2025-00123456",
    "code_name_network": "NajmNet",
    "remittance_type": "LOCAL",
    "amount": 150000.00,
    "notes": "حوالة من محمد أحمد في صنعاء"
}
```

### 📥 Response — نجاح `201 Created`

```json
{
    "message": "تم إرسال طلب الاستلام بنجاح وهو قيد المراجعة.",
    "operation_number": "3847291056",
    "status": "معلق — في انتظار المراجعة",
    "requested_at": "2025-04-02T17:45:00.000000Z"
}
```

### ❌ Response — خطأ `403 Forbidden`
```json
{
    "error": "هذه الخدمة متاحة فقط لمستخدمي التطبيق."
}
```

### ❌ Response — خطأ `400 Bad Request` (بيانات ناقصة)
```json
{
    "remittance_number": ["This field is required."],
    "code_name_network": ["This field is required."]
}
```

---

## 2. عرض طلبات الاستلام الخاصة بالمستخدم

**`GET /api/remittances/receipt-requests/my/`**

يعرض قائمة كاملة بجميع طلبات الاستلام التي أرسلها المستخدم الحالي مع كامل تفاصيلها وحالتها.

### 🔍 Query Parameters (اختيارية)

| المعامل | النوع | الوصف |
|---------|-------|-------|
| `status` | `string` | فلترة حسب الحالة: `PENDING` \| `APPROVED` \| `REJECTED` \| `CANCELLED` |

**مثال:** `GET /api/remittances/receipt-requests/my/?status=PENDING`

### 📥 Response — نجاح `200 OK`

```json
[
    {
        "operation_number": "3847291056",
        "remittance_number": "TRX-2025-00123456",
        "code_name_network": "NajmNet",
        "remittance_type": "LOCAL",
        "remittance_type_display": "محلية",
        "amount": "150000.00",
        "notes": "حوالة من محمد أحمد في صنعاء",
        "status": "PENDING",
        "status_display": "معلق — في انتظار المراجعة",
        "rejection_reason": null,
        "requested_at": "2025-04-02T17:45:00.000000Z",
        "responded_by_name": null,
        "responded_at": null
    },
    {
        "operation_number": "7291038475",
        "remittance_number": "NET-987654",
        "code_name_network": "AlImtiaz",
        "remittance_type": "INTERNATIONAL",
        "remittance_type_display": "دولية",
        "amount": "500.00",
        "notes": null,
        "status": "APPROVED",
        "status_display": "تمت الموافقة — تم الاستلام",
        "rejection_reason": null,
        "requested_at": "2025-04-01T10:30:00.000000Z",
        "responded_by_name": "أحمد محمد",
        "responded_at": "2025-04-01T11:05:00.000000Z"
    },
    {
        "operation_number": "1029384756",
        "remittance_number": "OLD-111222",
        "code_name_network": "SaifiNet",
        "remittance_type": "LOCAL",
        "remittance_type_display": "محلية",
        "amount": "75000.00",
        "notes": null,
        "status": "REJECTED",
        "status_display": "مرفوض",
        "rejection_reason": "رقم الحوالة غير صحيح أو غير موجود في النظام.",
        "requested_at": "2025-03-30T09:00:00.000000Z",
        "responded_by_name": "سارة خالد",
        "responded_at": "2025-03-30T09:45:00.000000Z"
    }
]
```

### 📌 شرح حقول الاستجابة

| الحقل | الوصف |
|-------|-------|
| `operation_number` | رقم العملية الفريد (10 أرقام) — يستخدم لتتبع الطلب أو إلغائه |
| `remittance_number` | رقم الحوالة الذي أدخله المستخدم |
| `code_name_network` | اسم/رمز الشبكة |
| `remittance_type` | `LOCAL` أو `INTERNATIONAL` |
| `remittance_type_display` | النص العربي لنوع الحوالة |
| `amount` | المبلغ (null إذا لم يُدخله المستخدم) |
| `notes` | الملاحظات |
| `status` | الرمز التقني للحالة |
| `status_display` | النص العربي للحالة (للعرض في الواجهة مباشرة) |
| `rejection_reason` | سبب الرفض — يظهر فقط عند `status = REJECTED` |
| `requested_at` | تاريخ ووقت إرسال الطلب (UTC) |
| `responded_by_name` | اسم الموظف الذي رد على الطلب |
| `responded_at` | تاريخ ووقت الرد (UTC) |

### 📌 قيم `status` الممكنة

| القيمة | المعنى | ما يجب عرضه للمستخدم |
|--------|--------|----------------------|
| `PENDING` | معلق | 🕐 قيد المراجعة |
| `APPROVED` | موافق عليه | ✅ تم الاستلام |
| `REJECTED` | مرفوض | ❌ مرفوض — اعرض `rejection_reason` |
| `CANCELLED` | ملغى | 🚫 تم الإلغاء |

---

## 3. إلغاء طلب معلق

**`POST /api/remittances/receipt-requests/<operation_number>/cancel/`**

يتيح للمستخدم إلغاء طلبه شريطة أن يكون لا يزال في حالة `PENDING`.

### 🔗 URL Parameter

| المعامل | الوصف |
|---------|-------|
| `operation_number` | رقم العملية المكون من 10 أرقام (من حقل `operation_number`) |

**مثال:** `POST /api/remittances/receipt-requests/3847291056/cancel/`

> لا يحتاج هذا الطلب إلى Body.

### 📥 Response — نجاح `200 OK`

```json
{
    "message": "تم إلغاء الطلب بنجاح.",
    "operation_number": "3847291056",
    "status": "ملغى من المستخدم"
}
```

### ❌ Response — محاولة إلغاء طلب غير معلق `400 Bad Request`

```json
{
    "error": "لا يمكن إلغاء طلب في حالة \"تمت الموافقة — تم الاستلام\"."
}
```

### ❌ Response — الطلب غير موجود `404 Not Found`

```json
{
    "error": "الطلب غير موجود."
}
```

---

## ملاحظات للمطور

> [!NOTE]
> جميع التواريخ والأوقات ترجع بصيغة **ISO 8601 UTC** مثال: `2025-04-02T17:45:00.000000Z`
> يمكن تحويلها للتوقيت المحلي في التطبيق حسب منطقة المستخدم.

> [!TIP]
> لعرض قائمة الطلبات المعلقة فقط في الصفحة الرئيسية استخدم:
> `GET /api/remittances/receipt-requests/my/?status=PENDING`
> وأعد الاستعلام عند فتح الشاشة لضمان حداثة البيانات.

> [!IMPORTANT]
> عند عرض طلب مرفوض `status = REJECTED` تأكد من إظهار حقل `rejection_reason` للمستخدم
> لأنه يحتوي على سبب الرفض الذي كتبه الموظف.
