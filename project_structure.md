# بنية المشروع والتقنيات - محفظة الصيفي

## 1. هيكل المشروع (Project Structure)

```
saifi_backend/
├── manage.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── README.md
├── saifi/
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── development.py
│   │   ├── production.py
│   │   └── testing.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   ├── __init__.py
│   ├── authentication/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── permissions.py
│   │   ├── utils.py
│   │   └── migrations/
│   ├── wallets/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── managers.py
│   │   ├── signals.py
│   │   └── migrations/
│   ├── transactions/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── validators.py
│   │   ├── services.py
│   │   └── migrations/
│   ├── payments/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── gateways/
│   │   │   ├── __init__.py
│   │   │   ├── base.py
│   │   │   ├── yemen_mobile.py
│   │   │   ├── mtn.py
│   │   │   └── sabafon.py
│   │   └── migrations/
│   ├── notifications/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── services.py
│   │   ├── firebase.py
│   │   └── migrations/
│   ├── reports/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── generators.py
│   │   └── migrations/
│   └── common/
│       ├── __init__.py
│       ├── models.py
│       ├── permissions.py
│       ├── pagination.py
│       ├── exceptions.py
│       ├── utils.py
│       ├── validators.py
│       └── middleware.py
├── core/
│   ├── __init__.py
│   ├── security.py
│   ├── encryption.py
│   ├── cache.py
│   ├── email.py
│   ├── sms.py
│   └── config.py
├── tests/
│   ├── __init__.py
│   ├── test_authentication.py
│   ├── test_wallets.py
│   ├── test_transactions.py
│   ├── test_payments.py
│   └── fixtures/
├── docs/
│   ├── api.md
│   ├── deployment.md
│   └── security.md
└── scripts/
    ├── deploy.sh
    ├── backup.sh
    └── migrate.sh
```

## 2. المتطلبات التقنية (Technical Requirements)

### 2.1 Python Dependencies
```txt
# requirements.txt
Django==4.2.7
djangorestframework==3.14.0
django-cors-headers==4.3.1
django-ratelimit==4.1.0
django-extensions==3.2.3
psycopg2-binary==2.9.7
redis==5.0.1
celery==5.3.4
djangorestframework-simplejwt==5.3.0
Pillow==10.1.0
python-decouple==3.8
cryptography==41.0.7
pyotp==2.9.0
phonenumbers==8.13.25
requests==2.31.0
gunicorn==21.2.0
whitenoise==6.6.0
sentry-sdk==1.38.0
django-storages==1.14.2
boto3==1.34.0
firebase-admin==6.2.0
twilio==8.10.0
pytest==7.4.3
pytest-django==4.7.0
coverage==7.3.2
black==23.11.0
flake8==6.1.0
```

### 2.2 Docker Configuration
```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: saifi_db
      POSTGRES_USER: saifi_user
      POSTGRES_PASSWORD: saifi_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  web:
    build: .
    command: gunicorn saifi.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
      - static_volume:/app/static
      - media_volume:/app/media
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis
    environment:
      - DEBUG=False
      - DATABASE_URL=postgresql://saifi_user:saifi_password@db:5432/saifi_db
      - REDIS_URL=redis://redis:6379/0

  celery:
    build: .
    command: celery -A saifi worker -l info
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgresql://saifi_user:saifi_password@db:5432/saifi_db
      - REDIS_URL=redis://redis:6379/0

  celery-beat:
    build: .
    command: celery -A saifi beat -l info
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgresql://saifi_user:saifi_password@db:5432/saifi_db
      - REDIS_URL=redis://redis:6379/0

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - static_volume:/app/static
      - media_volume:/app/media
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - web

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

### 2.3 Dockerfile
```dockerfile
# Dockerfile
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app/

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Run the application
CMD ["gunicorn", "saifi.wsgi:application", "--bind", "0.0.0.0:8000"]
```

## 3. إعدادات Django (Django Settings)

### 3.1 Base Settings
```python
# saifi/settings/base.py
import os
from pathlib import Path
from decouple import config

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Security
SECRET_KEY = config('SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# Application Definition
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'django_ratelimit',
    'django_extensions',
]

LOCAL_APPS = [
    'apps.authentication',
    'apps.wallets',
    'apps.transactions',
    'apps.payments',
    'apps.notifications',
    'apps.reports',
    'apps.common',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# Middleware
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'apps.common.middleware.SecurityMiddleware',
]

ROOT_URLCONF = 'saifi.urls'

# Templates
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

# Cache
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': config('REDIS_URL', default='redis://localhost:6379/0'),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

# Internationalization
LANGUAGE_CODE = 'ar'
TIME_ZONE = 'Asia/Aden'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'apps.common.pagination.StandardResultsSetPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'EXCEPTION_HANDLER': 'apps.common.exceptions.custom_exception_handler',
}

# JWT Settings
from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': config('JWT_SECRET_KEY'),
}

# Celery Configuration
CELERY_BROKER_URL = config('REDIS_URL', default='redis://localhost:6379/0')
CELERY_RESULT_BACKEND = config('REDIS_URL', default='redis://localhost:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE

# Email Configuration
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = config('EMAIL_HOST')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_HOST_USER = config('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL')

# Security Settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = config('SECURE_HSTS_SECONDS', default=0, cast=int)
SECURE_HSTS_INCLUDE_SUBDOMAINS = config('SECURE_HSTS_INCLUDE_SUBDOMAINS', default=False, cast=bool)
SECURE_HSTS_PRELOAD = config('SECURE_HSTS_PRELOAD', default=False, cast=bool)

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'django.log',
            'formatter': 'verbose',
        },
        'security': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'security.log',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
        'security': {
            'handlers': ['security'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

## 4. نماذج البيانات الأساسية (Core Models)

### 4.1 User Model
```python
# apps/authentication/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from core.encryption import Encryption

class User(AbstractUser):
    USER_TYPES = [
        ('CUSTOMER', 'Customer'),
        ('MERCHANT', 'Merchant'),
        ('ADMIN', 'Admin'),
    ]
    
    GENDER_CHOICES = [
        ('MALE', 'Male'),
        ('FEMALE', 'Female'),
    ]
    
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, unique=True)
    user_type = models.CharField(max_length=10, choices=USER_TYPES, default='CUSTOMER')
    national_id = models.CharField(max_length=20, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True)
    is_phone_verified = models.BooleanField(default=False)
    is_email_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'phone_number']
    
    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
    
    def __str__(self):
        return f"{self.username} ({self.email})"
```

### 4.2 Wallet Model
```python
# apps/wallets/models.py
from django.db import models
from django.core.validators import MinValueValidator
from django.conf import settings

class Wallet(models.Model):
    WALLET_TYPES = [
        ('PRIMARY', 'Primary'),
        ('SAVINGS', 'Savings'),
        ('BUSINESS', 'Business'),
    ]
    
    CURRENCIES = [
        ('YER', 'Yemeni Rial'),
        ('USD', 'US Dollar'),
        ('SAR', 'Saudi Riyal'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='wallets'
    )
    wallet_type = models.CharField(max_length=10, choices=WALLET_TYPES, default='PRIMARY')
    currency = models.CharField(max_length=3, choices=CURRENCIES, default='YER')
    balance = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)]
    )
    frozen_balance = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)]
    )
    daily_limit = models.DecimalField(max_digits=12, decimal_places=2, default=100000)
    monthly_limit = models.DecimalField(max_digits=12, decimal_places=2, default=500000)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'wallets'
        verbose_name = 'Wallet'
        verbose_name_plural = 'Wallets'
        unique_together = ['user', 'wallet_type', 'currency']
    
    def __str__(self):
        return f"{self.user.username} - {self.wallet_type} ({self.currency})"
    
    def available_balance(self):
        return self.balance - self.frozen_balance
```

## 5. الخدمات الخلفية (Background Services)

### 5.1 Celery Tasks
```python
# apps/transactions/tasks.py
from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings
from .models import Transaction
from apps.notifications.services import NotificationService

@shared_task
def process_transaction(transaction_id):
    """Process transaction in background"""
    try:
        transaction = Transaction.objects.get(id=transaction_id)
        # Process transaction logic here
        transaction.status = 'COMPLETED'
        transaction.save()
        
        # Send notification
        NotificationService.send_transaction_notification(transaction)
        
        return f"Transaction {transaction_id} processed successfully"
    except Exception as e:
        return f"Error processing transaction {transaction_id}: {str(e)}"

@shared_task
def send_daily_reports():
    """Send daily transaction reports to users"""
    # Implementation for daily reports
    pass

@shared_task
def cleanup_expired_tokens():
    """Clean up expired JWT tokens"""
    # Implementation for token cleanup
    pass
```

## 6. النشر (Deployment)

### 6.1 Nginx Configuration
```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream app {
        server web:8000;
    }

    server {
        listen 80;
        server_name yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name yourdomain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        client_max_body_size 20M;

        location /static/ {
            alias /app/static/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        location /media/ {
            alias /app/media/;
            expires 1y;
            add_header Cache-Control "public";
        }

        location / {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### 6.2 Deployment Script
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

echo "Starting deployment..."

# Pull latest code
git pull origin main

# Build and start containers
docker-compose down
docker-compose build
docker-compose up -d

# Run migrations
docker-compose exec web python manage.py migrate

# Collect static files
docker-compose exec web python manage.py collectstatic --noinput

# Restart services
docker-compose restart

echo "Deployment completed successfully!"
```

## 7. المراقبة والتحليل (Monitoring & Analytics)

### 7.1 Sentry Integration
```python
# saifi/settings/production.py
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration
from sentry_sdk.integrations.celery import CeleryIntegration

sentry_sdk.init(
    dsn=config('SENTRY_DSN'),
    integrations=[
        DjangoIntegration(
            transaction_style='url',
            middleware_spans=True,
            signals_spans=True,
        ),
        CeleryIntegration(
            monitor_beat_tasks=True,
            propagate_traces=True,
        ),
    ],
    traces_sample_rate=0.1,
    send_default_pii=True,
    environment='production',
)
```

## 8. اختبار الوحدة (Unit Testing)

### 8.1 Test Configuration
```python
# tests/test_transactions.py
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from apps.wallets.models import Wallet
from apps.transactions.models import Transaction

User = get_user_model()

class TransactionTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            phone_number='+967123456789',
            password='testpass123'
        )
        self.wallet = Wallet.objects.create(
            user=self.user,
            wallet_type='PRIMARY',
            balance=10000
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
    
    def test_create_transaction(self):
        data = {
            'from_wallet_id': self.wallet.id,
            'amount': '1000.00',
            'description': 'Test transaction'
        }
        response = self.client.post('/api/transactions/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Transaction.objects.count(), 1)
```

هذه البنية توفر أساساً قوياً لنظام محفظة الصيفي مع التركيز على الأمان وقابلية التوسع وأفضل الممارسات في تطوير Django.
