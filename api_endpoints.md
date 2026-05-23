# API Endpoints لمحفظة الصيفي - Django REST Framework

## 1. المصادقة والمستخدمين (Authentication & Users)

### تسجيل الدخول
```
POST /api/auth/login/
{
  "phone_number": "+967123456789",
  "password": "password123",
  "device_id": "device_token",
  "user_type": "customer" // customer, merchant
}
Response:
{
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": {...},
  "wallets": [...]
}
```

### تسجيل الدخول بالبصمة
```
POST /api/auth/biometric-login/
{
  "device_id": "device_token",
  "biometric_data": "encrypted_data",
  "user_type": "customer"
}
```

### تسجيل مستخدم جديد
```
POST /api/auth/register/
{
  "username": "username",
  "email": "email@example.com",
  "phone_number": "+967123456789",
  "password": "password123",
  "full_name": "Full Name",
  "national_id": "123456789",
  "date_of_birth": "1990-01-01",
  "gender": "male"
}
```

### تحديث التوكن
```
POST /api/auth/refresh/
{
  "refresh_token": "refresh_token"
}
```

### تسجيل الخروج
```
POST /api/auth/logout/
{
  "refresh_token": "refresh_token"
}
```

## 2. المحافظ والأرصدة (Wallets & Balances)

### الحصول على محافظ المستخدم
```
GET /api/wallets/
Headers: Authorization: Bearer {token}
Response:
{
  "count": 2,
  "results": [
    {
      "id": 1,
      "wallet_type": "primary",
      "currency": "YER",
      "balance": "50000.00",
      "frozen_balance": "0.00",
      "daily_limit": "100000.00",
      "monthly_limit": "500000.00"
    }
  ]
}
```

### إنشاء محفظة جديدة
```
POST /api/wallets/
{
  "wallet_type": "savings",
  "currency": "YER"
}
```

### الحصول على تفاصيل المحفظة
```
GET /api/wallets/{wallet_id}/
```

### إخفاء/إظهار الرصيد
```
PATCH /api/wallets/{wallet_id}/balance-visibility/
{
  "is_hidden": true
}
```

## 3. المعاملات المالية (Transactions)

### الحصول على قائمة المعاملات
```
GET /api/transactions/?wallet_id=1&page=1&page_size=20
Headers: Authorization: Bearer {token}
Query Parameters:
- wallet_id: filter by wallet
- transaction_type: TRANSFER, PAYMENT, DEPOSIT, WITHDRAWAL
- status: PENDING, COMPLETED, FAILED
- date_from: 2024-01-01
- date_to: 2024-12-31
- category: food, transport, bills

Response:
{
  "count": 150,
  "next": "http://api/transactions/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "transaction_id": "TXN202401010001",
      "from_wallet": {"id": 1, "type": "primary"},
      "to_wallet": {"id": 2, "type": "savings"},
      "amount": "5000.00",
      "currency": "YER",
      "transaction_type": "TRANSFER",
      "status": "COMPLETED",
      "description": "Transfer to savings",
      "fees": "5.00",
      "created_at": "2024-01-01T10:00:00Z",
      "category": {"name": "transfer", "icon": "swap"}
    }
  ]
}
```

### تحويل أموال بين المحافظ
```
POST /api/transactions/transfer/
{
  "from_wallet_id": 1,
  "to_wallet_id": 2,
  "amount": "5000.00",
  "description": "Monthly savings",
  "category_id": 1
}
```

### تحويل إلى مستخدم آخر
```
POST /api/transactions/transfer-to-user/
{
  "from_wallet_id": 1,
  "recipient_phone": "+967987654321",
  "amount": "1000.00",
  "description": "Payment for services"
}
```

### الحصول على تفاصيل معاملة
```
GET /api/transactions/{transaction_id}/
```

## 4. التحويلات المالية المتقدمة (Advanced Transfers)

### تحويل إلى مشترك
```
POST /api/transfers/to-subscriber/
{
  "from_wallet_id": 1,
  "subscriber_phone": "+967123456789",
  "amount": "5000.00",
  "description": "Payment"
}
```

### تحويل بين حساباتي
```
POST /api/transfers/between-accounts/
{
  "from_wallet_id": 1,
  "to_wallet_id": 2,
  "amount": "10000.00"
}
```

### حوالات الشبكات المحلية
```
POST /api/transfers/local-network/
{
  "from_wallet_id": 1,
  "network_provider": "yemen_mobile",
  "recipient_number": "+967123456789",
  "amount": "5000.00"
}
```

### طلب استلام حوالة
```
POST /api/transfers/request-receipt/
{
  "transfer_code": "LOCAL123456",
  "wallet_id": 1
}
```

### تحويل إلى بنوك ومحافظ أخرى
```
POST /api/transfers/to-banks/
{
  "from_wallet_id": 1,
  "bank_account_id": 1,
  "amount": "50000.00",
  "bank_name": "CBY"
}
```

## 5. دفع الفواتير (Bill Payments)

### الحصول على قائمة الفواتير
```
GET /api/bills/
Response:
{
  "results": [
    {
      "id": 1,
      "service": {"name": "Electricity", "icon": "bolt"},
      "bill_number": "EL123456",
      "amount": "15000.00",
      "due_date": "2024-01-15",
      "status": "PENDING"
    }
  ]
}
```

### دفع فاتورة
```
POST /api/bills/pay/
{
  "bill_id": 1,
  "wallet_id": 1,
  "amount": "15000.00"
}
```

### إضافة فاتورة جديدة
```
POST /api/bills/
{
  "service_id": 1,
  "bill_number": "EL123456",
  "amount": "15000.00",
  "due_date": "2024-01-15"
}
```

## 6. الشحن والخدمات (Recharge & Services)

### شحن رصيد هاتف
```
POST /api/recharge/phone/
{
  "wallet_id": 1,
  "phone_number": "+967123456789",
  "amount": "1000.00",
  "operator": "yemen_mobile"
}
```

### شحن إنترنت
```
POST /api/recharge/internet/
{
  "wallet_id": 1,
  "phone_number": "+967123456789",
  "package_id": "daily_1gb",
  "amount": "500.00"
}
```

### دفع خدمات حكومية
```
POST /api/payments/government/
{
  "wallet_id": 1,
  "service_type": "sadaad",
  "reference_number": "GOV123456",
  "amount": "25000.00"
}
```

## 7. البطاقات والحسابات البنكية (Cards & Bank Accounts)

### الحصول على البطاقات المحفوظة
```
GET /api/cards/
```

### إضافة بطاقة جديدة
```
POST /api/cards/
{
  "card_type": "debit",
  "card_number": "4111111111111111",
  "expiry_month": "12",
  "expiry_year": "2025",
  "cardholder_name": "John Doe"
}
```

### الحصول على الحسابات البنكية
```
GET /api/bank-accounts/
```

### إضافة حساب بنكي
```
POST /api/bank-accounts/
{
  "bank_name": "CBY",
  "account_number": "123456789",
  "account_holder_name": "John Doe",
  "iban": "YE000000000000000000000"
}
```

## 8. الإشعارات (Notifications)

### الحصول على الإشعارات
```
GET /api/notifications/?page=1&unread_only=true
Response:
{
  "results": [
    {
      "id": 1,
      "type": "TRANSACTION",
      "title": "Transfer Completed",
      "message": "You received 5000 YER from +967123456789",
      "is_read": false,
      "created_at": "2024-01-01T10:00:00Z"
    }
  ]
}
```

### تحديث حالة القراءة
```
PATCH /api/notifications/{notification_id}/
{
  "is_read": true
}
```

## 9. التقارير والإحصائيات (Reports & Analytics)

### تقرير المعاملات
```
GET /api/reports/transactions/?start_date=2024-01-01&end_date=2024-01-31
Response:
{
  "total_transactions": 50,
  "total_amount": "150000.00",
  "by_category": [
    {"category": "food", "count": 20, "amount": "50000.00"},
    {"category": "transport", "count": 10, "amount": "30000.00"}
  ],
  "daily_breakdown": [...]
}
```

### تقرير الرصيد
```
GET /api/reports/balance/?wallet_id=1
```

## 10. إعدادات المستخدم (User Settings)

### الحصول على ملف المستخدم
```
GET /api/users/profile/
```

### تحديث ملف المستخدم
```
PATCH /api/users/profile/
{
  "full_name": "Updated Name",
  "email": "newemail@example.com",
  "address": "New Address"
}
```

### تغيير كلمة المرور
```
POST /api/users/change-password/
{
  "old_password": "oldpass123",
  "new_password": "newpass123"
}
```

### إعدادات الإشعارات
```
PATCH /api/users/notification-settings/
{
  "transaction_notifications": true,
  "promotional_notifications": false,
  "security_notifications": true
}
```

## 11. نقاط البيع (POS - Merchants)

### تسجيل تاجر جديد
```
POST /api/merchants/register/
{
  "business_name": "My Store",
  "business_type": "retail",
  "license_number": "BIZ123456",
  "commission_rate": "2.5"
}
```

### معالجة دفعة من نقطة بيع
```
POST /api/pos/process-payment/
{
  "merchant_id": 1,
  "customer_phone": "+967123456789",
  "amount": "5000.00",
  "description": "Purchase at My Store"
}
```

## 12. دعم العملاء (Customer Support)

### إنشاء تذكرة دعم
```
POST /api/support/tickets/
{
  "subject": "Transaction Issue",
  "description": "I have a problem with transaction TXN123456",
  "priority": "high"
}
```

### الحصول على تذاكر الدعم
```
GET /api/support/tickets/
```

### إضافة رسالة لتذكرة
```
POST /api/support/tickets/{ticket_id}/messages/
{
  "message": "Additional information about the issue"
}
```

## 13. الإعدادات العامة (System Settings)

### أسعار الصرف
```
GET /api/system/exchange-rates/
Response:
{
  "YER_TO_USD": "0.0040",
  "YER_TO_SAR": "0.0150",
  "USD_TO_YER": "250.0000"
}
```

### رسوم الخدمات
```
GET /api/system/fees/
Response:
{
  "transfer_fee": {
    "fixed_fee": "5.00",
    "percentage_fee": "0.01"
  },
  "withdrawal_fee": {
    "fixed_fee": "10.00",
    "percentage_fee": "0.02"
  }
}
```
