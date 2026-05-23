# مخطط جداول قاعدة بيانات محفظة الصيفي

## 1. المستخدمون والمصادقة

### User (المستخدمين)
```sql
- id (PK)
- username (unique)
- email (unique)
- phone_number (unique)
- password_hash
- full_name
- user_type (enum: CUSTOMER, MERCHANT, ADMIN)
- is_active
- is_verified
- created_at
- updated_at
- last_login
- profile_image
- national_id
- date_of_birth
- gender
```

### UserProfile (ملف المستخدم)
```sql
- id (PK)
- user_id (FK -> User)
- bio
- address
- city
- country
- postal_code
- preferred_language
- timezone
- notification_settings
- privacy_settings
```

### Device (الأجهزة)
```sql
- id (PK)
- user_id (FK -> User)
- device_id (unique)
- device_type (enum: ANDROID, IOS)
- device_token
- is_active
- last_used_at
- created_at
```

## 2. المحافظ والمعاملات

### Wallet (المحافظ)
```sql
- id (PK)
- user_id (FK -> User)
- wallet_type (enum: PRIMARY, SAVINGS, BUSINESS)
- currency (enum: YER, USD, SAR)
- balance (decimal)
- frozen_balance (decimal)
- is_active
- created_at
- updated_at
- daily_limit
- monthly_limit
```

### Transaction (المعاملات)
```sql
- id (PK)
- transaction_id (unique string)
- from_wallet_id (FK -> Wallet)
- to_wallet_id (FK -> Wallet, nullable)
- amount (decimal)
- currency
- transaction_type (enum: TRANSFER, PAYMENT, DEPOSIT, WITHDRAWAL)
- status (enum: PENDING, COMPLETED, FAILED, CANCELLED)
- description
- reference_id
- fees (decimal)
- created_at
- completed_at
- external_reference
- category
```

### TransactionCategory (فئات المعاملات)
```sql
- id (PK)
- name
- icon
- color
- parent_id (FK -> self)
- is_active
```

## 3. الخدمات والمدفوعات

### Service (الخدمات)
```sql
- id (PK)
- name
- description
- service_type (enum: BILL_PAYMENT, RECHARGE, TRANSFER)
- provider
- is_active
- fees_percentage
- fixed_fees
- icon
- created_at
```

### BillPayment (دفع الفواتير)
```sql
- id (PK)
- user_id (FK -> User)
- service_id (FK -> Service)
- bill_number
- amount
- due_date
- status (enum: PENDING, PAID, OVERDUE)
- paid_at
- transaction_id (FK -> Transaction)
```

### Recharge (الشحن)
```sql
- id (PK)
- user_id (FK -> User)
- phone_number
- amount
- operator (enum: YEMEN_MOBILE, MTN, SABAFON)
- status
- transaction_id (FK -> Transaction)
- created_at
```

## 4. البطاقات والحسابات البنكية

### BankAccount (الحسابات البنكية)
```sql
- id (PK)
- user_id (FK -> User)
- bank_name
- account_number
- account_holder_name
- iban
- is_verified
- is_default
- created_at
```

### Card (البطاقات)
```sql
- id (PK)
- user_id (FK -> User)
- card_type (enum: DEBIT, CREDIT)
- last_four_digits
- expiry_month
- expiry_year
- cardholder_name
- is_default
- is_active
- token
- created_at
```

## 5. الأمان والتحقق

### BiometricAuth (المصادقة البيومترية)
```sql
- id (PK)
- user_id (FK -> User)
- device_id (FK -> Device)
- biometric_type (enum: FINGERPRINT, FACE_ID)
- public_key
- is_active
- created_at
```

### SecurityLog (سجل الأمان)
```sql
- id (PK)
- user_id (FK -> User)
- action (enum: LOGIN, LOGOUT, TRANSACTION, PASSWORD_CHANGE)
- ip_address
- user_agent
- success
- failure_reason
- created_at
```

### TwoFactorAuth (المصادقة الثنائية)
```sql
- id (PK)
- user_id (FK -> User)
- secret_key
- backup_codes
- is_enabled
- created_at
```

## 6. الإشعارات والتقارير

### Notification (الإشعارات)
```sql
- id (PK)
- user_id (FK -> User)
- type (enum: TRANSACTION, SECURITY, PROMOTIONAL)
- title
- message
- data (JSON)
- is_read
- created_at
```

### Report (التقارير)
```sql
- id (PK)
- user_id (FK -> User)
- report_type (enum: TRANSACTIONS, BALANCE, TAX)
- parameters (JSON)
- file_path
- generated_at
```

## 7. التجار ونقاط البيع

### Merchant (التجار)
```sql
- id (PK)
- user_id (FK -> User)
- business_name
- business_type
- license_number
- commission_rate
- is_verified
- created_at
```

### POS (نقاط البيع)
```sql
- id (PK)
- merchant_id (FK -> Merchant)
- device_id
- location
- is_active
- created_at
```

## 8. العمولة والعمولات

### Fee (العمولة)
```sql
- id (PK)
- fee_type (enum: TRANSACTION, WITHDRAWAL, TRANSFER)
- min_amount
- max_amount
- fixed_fee
- percentage_fee
- currency
- is_active
```

### Commission (العمولات)
```sql
- id (PK)
- merchant_id (FK -> Merchant)
- transaction_id (FK -> Transaction)
- amount
- commission_rate
- created_at
```

## 9. دعم العملاء

### SupportTicket (تذاكر الدعم)
```sql
- id (PK)
- user_id (FK -> User)
- subject
- description
- status (enum: OPEN, IN_PROGRESS, RESOLVED, CLOSED)
- priority (enum: LOW, MEDIUM, HIGH, URGENT)
- assigned_to (FK -> User)
- created_at
- resolved_at
```

### TicketMessage (رسائل التذكرة)
```sql
- id (PK)
- ticket_id (FK -> SupportTicket)
- sender_id (FK -> User)
- message
- attachments (JSON)
- is_internal
- created_at
```

## 10. الإعدادات والتكوين

### SystemSettings (إعدادات النظام)
```sql
- id (PK)
- key (unique)
- value
- description
- data_type (enum: STRING, NUMBER, BOOLEAN, JSON)
- is_public
```

### CurrencyExchange (أسعار الصرف)
```sql
- id (PK)
- from_currency
- to_currency
- rate
- source
- updated_at
```
