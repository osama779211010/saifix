# القيود الأمنية والتحقق - محفظة الصيفي

## 1. طبقات الأمان (Security Layers)

### 1.1 أمان الشبكة (Network Security)
```python
# HTTPS إجباري
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# CORS Settings
CORS_ALLOWED_ORIGINS = [
    "https://yourapp.com",
    "https://api.yourapp.com"
]
CORS_ALLOW_CREDENTIALS = True

# Rate Limiting
RATELIMIT_ENABLE = True
RATELIMIT_USE_CACHE = 'default'
```

### 1.2 مصادقة JWT (JWT Authentication)
```python
# JWT Settings
JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY')
JWT_ALGORITHM = 'HS256'
JWT_ACCESS_TOKEN_LIFETIME = timedelta(minutes=15)
JWT_REFRESH_TOKEN_LIFETIME = timedelta(days=7)
JWT_BLACKLIST_ENABLED = True

# Custom JWT Payload
def jwt_payload_handler(user):
    return {
        'user_id': user.id,
        'username': user.username,
        'user_type': user.user_type,
        'exp': datetime.utcnow() + JWT_ACCESS_TOKEN_LIFETIME,
        'iat': datetime.utcnow(),
        'jti': str(uuid.uuid4())  # Unique token ID
    }
```

## 2. التحقق من الهوية (Authentication & Authorization)

### 2.1 المصادقة الثنائية (2FA)
```python
# Two-Factor Authentication
class TwoFactorAuth(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    secret_key = models.CharField(max_length=32)
    backup_codes = models.JSONField(default=list)
    is_enabled = models.BooleanField(default=False)
    
    def generate_backup_codes(self):
        return [str(random.randint(100000, 999999)) for _ in range(10)]
    
    def verify_totp(self, token):
        totp = pyotp.TOTP(self.secret_key)
        return totp.verify(token, valid_window=1)
```

### 2.3 المصادقة البيومترية
```python
# Biometric Authentication
class BiometricAuth(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    device_id = models.CharField(max_length=255)
    biometric_type = models.CharField(max_length=20, choices=[
        ('FINGERPRINT', 'Fingerprint'),
        ('FACE_ID', 'Face ID')
    ])
    public_key = models.TextField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'device_id', 'biometric_type']
```

## 3. تشفير البيانات (Data Encryption)

### 3.1 تشفير البيانات الحساسة
```python
from cryptography.fernet import Fernet
import base64
import os

class Encryption:
    def __init__(self):
        self.key = os.environ.get('ENCRYPTION_KEY').encode()
        self.cipher_suite = Fernet(self.key)
    
    def encrypt(self, data):
        if isinstance(data, str):
            data = data.encode()
        return self.cipher_suite.encrypt(data).decode()
    
    def decrypt(self, encrypted_data):
        if isinstance(encrypted_data, str):
            encrypted_data = encrypted_data.encode()
        return self.cipher_suite.decrypt(encrypted_data).decode()

# Usage in models
class BankAccount(models.Model):
    account_number = models.CharField(max_length=255)
    _account_number_encrypted = models.TextField(db_column='account_number_encrypted')
    
    def save(self, *args, **kwargs):
        encryption = Encryption()
        self._account_number_encrypted = encryption.encrypt(self.account_number)
        super().save(*args, **kwargs)
```

### 3.2 تجزئة كلمات المرور
```python
import hashlib
import secrets
import bcrypt

class PasswordManager:
    @staticmethod
    def hash_password(password):
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
    
    @staticmethod
    def verify_password(password, hashed):
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    
    @staticmethod
    def generate_secure_token(length=32):
        return secrets.token_urlsafe(length)
```

## 4. التحقق من المعاملات (Transaction Validation)

### 4.1 قيود المعاملات
```python
class TransactionValidator:
    @staticmethod
    def validate_transaction_amount(wallet, amount):
        # Check daily limit
        daily_total = Transaction.objects.filter(
            from_wallet=wallet,
            created_at__date=timezone.now().date(),
            status='COMPLETED'
        ).aggregate(total=models.Sum('amount'))['total'] or 0
        
        if daily_total + amount > wallet.daily_limit:
            raise ValidationError("Daily transaction limit exceeded")
        
        # Check monthly limit
        monthly_total = Transaction.objects.filter(
            from_wallet=wallet,
            created_at__month=timezone.now().month,
            created_at__year=timezone.now().year,
            status='COMPLETED'
        ).aggregate(total=models.Sum('amount'))['total'] or 0
        
        if monthly_total + amount > wallet.monthly_limit:
            raise ValidationError("Monthly transaction limit exceeded")
        
        # Check balance
        if wallet.balance < amount:
            raise ValidationError("Insufficient balance")
    
    @staticmethod
    def validate_recipient(phone_number):
        # Validate phone number format
        if not re.match(r'^\+967\d{9}$', phone_number):
            raise ValidationError("Invalid Yemeni phone number")
        
        # Check if recipient exists
        if not User.objects.filter(phone_number=phone_number).exists():
            raise ValidationError("Recipient not found")
```

### 4.2 التحقق من الاحتيال (Fraud Detection)
```python
class FraudDetection:
    @staticmethod
    def check_suspicious_activity(user, transaction):
        # Check for rapid successive transactions
        recent_transactions = Transaction.objects.filter(
            from_wallet__user=user,
            created_at__gte=timezone.now() - timedelta(minutes=5)
        ).count()
        
        if recent_transactions > 5:
            return True, "Too many transactions in short time"
        
        # Check for unusual amount
        avg_amount = Transaction.objects.filter(
            from_wallet__user=user,
            status='COMPLETED'
        ).aggregate(avg=models.Avg('amount'))['avg'] or 0
        
        if transaction.amount > avg_amount * 10:
            return True, "Unusually large transaction amount"
        
        # Check for new recipient
        recipient_exists = Transaction.objects.filter(
            to_wallet__user__phone_number=transaction.recipient_phone,
            from_wallet__user=user
        ).exists()
        
        if not recipient_exists and transaction.amount > 50000:
            return True, "Large amount to new recipient"
        
        return False, None
```

## 5. أمان الـ API (API Security)

### 5.1 Rate Limiting
```python
from django_ratelimit.decorators import ratelimit
from django.core.cache import cache

class RateLimitMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Different limits for different endpoints
        if request.path.startswith('/api/auth/login'):
            # 5 attempts per minute for login
            key = f"login_{request.META.get('REMOTE_ADDR')}"
            attempts = cache.get(key, 0)
            
            if attempts >= 5:
                return JsonResponse({'error': 'Too many login attempts'}, status=429)
            
            cache.set(key, attempts + 1, 60)
        
        response = self.get_response(request)
        return response

# Decorator usage
@ratelimit(key='ip', rate='5/m', method='POST')
def login_view(request):
    pass
```

### 5.2 Input Validation
```python
from django.core.validators import RegexValidator
from rest_framework import serializers

class TransactionSerializer(serializers.ModelSerializer):
    amount = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2,
        min_value=0.01,
        max_value=1000000
    )
    
    recipient_phone = serializers.CharField(
        validators=[
            RegexValidator(
                regex=r'^\+967\d{9}$',
                message='Invalid Yemeni phone number'
            )
        ]
    )
    
    def validate(self, data):
        # Custom validation logic
        if data['amount'] < 100:
            raise serializers.ValidationError("Minimum amount is 100 YER")
        return data
```

## 6. سجل الأمان (Security Logging)

### 6.1 Security Events Logging
```python
import logging

security_logger = logging.getLogger('security')

class SecurityMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Log authentication attempts
        if request.path.startswith('/api/auth/'):
            security_logger.info(f"Auth attempt from {request.META.get('REMOTE_ADDR')}")
        
        # Log suspicious activities
        if request.method == 'POST' and request.path.startswith('/api/transactions/'):
            user = request.user if request.user.is_authenticated else None
            security_logger.info(f"Transaction attempt by user {user.id if user else 'anonymous'}")
        
        response = self.get_response(request)
        return response

# Model for security logs
class SecurityLog(models.Model):
    ACTION_CHOICES = [
        ('LOGIN', 'Login'),
        ('LOGOUT', 'Logout'),
        ('TRANSACTION', 'Transaction'),
        ('PASSWORD_CHANGE', 'Password Change'),
        ('FAILED_LOGIN', 'Failed Login'),
        ('SUSPICIOUS_ACTIVITY', 'Suspicious Activity')
    ]
    
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    success = models.BooleanField(default=True)
    failure_reason = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    additional_data = models.JSONField(default=dict)
```

## 7. حماية البيانات الشخصية (Data Privacy)

### 7.1 GDPR Compliance
```python
class DataPrivacyManager:
    @staticmethod
    def anonymize_user_data(user):
        # Anonymize personal data
        user.email = f"deleted_{user.id}@deleted.com"
        user.phone_number = f"+967000000{user.id:04d}"
        user.full_name = "Deleted User"
        user.national_id = "000000000"
        user.is_active = False
        user.save()
    
    @staticmethod
    def export_user_data(user):
        # Export all user data in JSON format
        data = {
            'personal_info': {
                'username': user.username,
                'email': user.email,
                'phone_number': user.phone_number,
                'full_name': user.full_name,
                'date_of_birth': user.date_of_birth,
                'created_at': user.created_at
            },
            'wallets': [],
            'transactions': [],
            'cards': [],
            'bank_accounts': []
        }
        
        # Add wallet data
        for wallet in user.wallet_set.all():
            data['wallets'].append({
                'id': wallet.id,
                'type': wallet.wallet_type,
                'currency': wallet.currency,
                'balance': str(wallet.balance)
            })
        
        return data
```

## 8. اختبار الاختراق (Penetration Testing)

### 8.1 Security Tests
```python
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase

class SecurityTests(APITestCase):
    def test_sql_injection_protection(self):
        # Test SQL injection attempts
        malicious_input = "'; DROP TABLE users; --"
        response = self.client.post('/api/auth/login/', {
            'username': malicious_input,
            'password': 'password'
        })
        self.assertNotEqual(response.status_code, 500)
    
    def test_xss_protection(self):
        # Test XSS protection
        xss_payload = "<script>alert('xss')</script>"
        response = self.client.post('/api/users/profile/', {
            'full_name': xss_payload
        })
        self.assertNotIn('<script>', response.content.decode())
    
    def test_rate_limiting(self):
        # Test rate limiting
        for i in range(10):
            response = self.client.post('/api/auth/login/', {
                'username': 'test',
                'password': 'wrong'
            })
        
        self.assertEqual(response.status_code, 429)
```

## 9. إعدادات الأمان الإنتاجية (Production Security)

### 9.1 Environment Variables
```bash
# .env file
SECRET_KEY=your-super-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here
ENCRYPTION_KEY=your-encryption-key-here
DATABASE_URL=postgresql://user:password@localhost/saifi_db
REDIS_URL=redis://localhost:6379/0
ALLOWED_HOSTS=yourdomain.com,api.yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourapp.com
```

### 9.2 Docker Security
```dockerfile
# Use non-root user
FROM python:3.11-slim
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Minimal packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Security headers in nginx
server {
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
}
```

## 10. المراقبة والتنبيه (Monitoring & Alerts)

### 10.1 Security Monitoring
```python
class SecurityMonitor:
    @staticmethod
    def check_anomalies():
        # Check for unusual login patterns
        recent_failed_logins = SecurityLog.objects.filter(
            action='FAILED_LOGIN',
            created_at__gte=timezone.now() - timedelta(hours=1)
        ).count()
        
        if recent_failed_logins > 50:
            send_security_alert("High number of failed login attempts detected")
        
        # Check for large transactions
        large_transactions = Transaction.objects.filter(
            amount__gt=100000,
            created_at__gte=timezone.now() - timedelta(hours=1)
        ).count()
        
        if large_transactions > 10:
            send_security_alert("Multiple large transactions detected")
    
    @staticmethod
    def send_security_alert(message):
        # Send alert to security team
        # Implementation depends on your alerting system
        pass
```
