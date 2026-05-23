import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class OperationTypeHelper {
  static IconData getIcon(String operationType) {
    switch (operationType) {
      // التحويلات والمصارفة
      case 'P2P_TRANSFER_SEND':
        return Icons.send_rounded;
      case 'P2P_TRANSFER_RECV':
        return Icons.call_received_rounded;
      case 'CURRENCY_EXCHANGE':
        return Icons.currency_exchange_rounded;
      case 'REMIT_SEND':
        return Icons.upload_rounded;
      case 'REMIT_RECV':
        return Icons.download_rounded;
      
      // المدفوعات والشحن
      case 'RECHARGE':
        return Icons.phone_android_rounded;
      case 'BILL_PAYMENT':
        return Icons.receipt_long_rounded;
      case 'PURCHASE_SERVICE':
        return Icons.shopping_bag_rounded;
      case 'POS_PAYMENT':
        return Icons.storefront_rounded;
      case 'POS_SALES_RECEIPT':
        return Icons.point_of_sale_rounded;
      
      // خدمات الوكلاء
      case 'AGENT_WITHDRAW_REQ':
        return Icons.money_off_rounded;
      case 'AGENT_WITHDRAW_CONFIRM':
        return Icons.check_circle_rounded;
      case 'AGENT_DEPOSIT_TO_USER':
        return Icons.account_balance_wallet_rounded;
      case 'AGENT_DEPOSIT_TO_POS':
        return Icons.store_rounded;
      
      // الجمعيات / المجموعات
      case 'COLLECTION_CREATE':
        return Icons.group_add_rounded;
      case 'COLLECTION_PAY':
        return Icons.payment_rounded;
      case 'COLLECTION_RECEIVE':
        return Icons.groups_rounded;
      case 'COLLECTION_FINAL_PAY':
        return Icons.done_all_rounded;
      
      // العائلة والحصالات
      case 'SUB_WALLET_DEPOSIT':
        return Icons.family_restroom_rounded;
      case 'SUB_WALLET_RECEIVE':
        return Icons.card_giftcard_rounded;
      case 'SUB_WALLET_WITHDRAW':
        return Icons.money_off_csred_rounded;
      case 'PIGGYBANK_CREATE':
        return Icons.savings_rounded;
      case 'PIGGYBANK_DEPOSIT':
        return Icons.add_circle_rounded;
      case 'PIGGYBANK_WITHDRAW':
        return Icons.remove_circle_rounded;
      
      // عمليات عامة
      case 'REFUND':
        return Icons.assignment_return_rounded;
      case 'COMMISSION_EARN':
        return Icons.trending_up_rounded;
      
      default:
        return Icons.receipt_rounded;
    }
  }

  static Color getColor(String operationType, bool isDarkMode) {
    switch (operationType) {
      // التحويلات - أزرق
      case 'P2P_TRANSFER_SEND':
      case 'P2P_TRANSFER_RECV':
      case 'CURRENCY_EXCHANGE':
        return AppColors.primaryBlue;
      
      // الحوالات الخارجية - برتقالي
      case 'REMIT_SEND':
      case 'REMIT_RECV':
        return Colors.orange;
      
      // المدفوعات والشحن - أخضر
      case 'RECHARGE':
      case 'BILL_PAYMENT':
      case 'PURCHASE_SERVICE':
        return Colors.green;
      
      // نقاط البيع - بنفسجي
      case 'POS_PAYMENT':
      case 'POS_SALES_RECEIPT':
        return Colors.purple;
      
      // خدمات الوكلاء - أحمر
      case 'AGENT_WITHDRAW_REQ':
      case 'AGENT_WITHDRAW_CONFIRM':
      case 'AGENT_DEPOSIT_TO_USER':
      case 'AGENT_DEPOSIT_TO_POS':
        return Colors.red;
      
      // الجمعيات - سماوي
      case 'COLLECTION_CREATE':
      case 'COLLECTION_PAY':
      case 'COLLECTION_RECEIVE':
      case 'COLLECTION_FINAL_PAY':
        return Colors.cyan;
      
      // العائلة والحصالات - وردي
      case 'SUB_WALLET_DEPOSIT':
      case 'SUB_WALLET_RECEIVE':
      case 'SUB_WALLET_WITHDRAW':
      case 'PIGGYBANK_CREATE':
      case 'PIGGYBANK_DEPOSIT':
      case 'PIGGYBANK_WITHDRAW':
        return Colors.pink;
      
      // عمليات عامة - أصفر
      case 'REFUND':
        return Colors.amber;
      case 'COMMISSION_EARN':
        return Colors.lime;
      
      default:
        return isDarkMode ? Colors.white54 : Colors.black54;
    }
  }

  static String getCategory(String operationType) {
    switch (operationType) {
      case 'P2P_TRANSFER_SEND':
      case 'P2P_TRANSFER_RECV':
      case 'CURRENCY_EXCHANGE':
        return 'transfers';
      case 'REMIT_SEND':
      case 'REMIT_RECV':
        return 'remittances';
      case 'RECHARGE':
      case 'BILL_PAYMENT':
      case 'PURCHASE_SERVICE':
        return 'payments';
      case 'POS_PAYMENT':
      case 'POS_SALES_RECEIPT':
        return 'pos';
      case 'AGENT_WITHDRAW_REQ':
      case 'AGENT_WITHDRAW_CONFIRM':
      case 'AGENT_DEPOSIT_TO_USER':
      case 'AGENT_DEPOSIT_TO_POS':
        return 'agent';
      case 'COLLECTION_CREATE':
      case 'COLLECTION_PAY':
      case 'COLLECTION_RECEIVE':
      case 'COLLECTION_FINAL_PAY':
        return 'collections';
      case 'SUB_WALLET_DEPOSIT':
      case 'SUB_WALLET_RECEIVE':
      case 'SUB_WALLET_WITHDRAW':
      case 'PIGGYBANK_CREATE':
      case 'PIGGYBANK_DEPOSIT':
      case 'PIGGYBANK_WITHDRAW':
        return 'family';
      case 'REFUND':
      case 'COMMISSION_EARN':
        return 'general';
      default:
        return 'other';
    }
  }

  static List<String> getAllOperationTypes() {
    return [
      // التحويلات والمصارفة
      'P2P_TRANSFER_SEND',
      'P2P_TRANSFER_RECV',
      'CURRENCY_EXCHANGE',
      'REMIT_SEND',
      'REMIT_RECV',
      
      // المدفوعات والشحن
      'RECHARGE',
      'BILL_PAYMENT',
      'PURCHASE_SERVICE',
      'POS_PAYMENT',
      'POS_SALES_RECEIPT',
      
      // خدمات الوكلاء
      'AGENT_WITHDRAW_REQ',
      'AGENT_WITHDRAW_CONFIRM',
      'AGENT_DEPOSIT_TO_USER',
      'AGENT_DEPOSIT_TO_POS',
      
      // الجمعيات / المجموعات
      'COLLECTION_CREATE',
      'COLLECTION_PAY',
      'COLLECTION_RECEIVE',
      'COLLECTION_FINAL_PAY',
      
      // العائلة والحصالات
      'SUB_WALLET_DEPOSIT',
      'SUB_WALLET_RECEIVE',
      'SUB_WALLET_WITHDRAW',
      'PIGGYBANK_CREATE',
      'PIGGYBANK_DEPOSIT',
      'PIGGYBANK_WITHDRAW',
      
      // عمليات عامة
      'REFUND',
      'COMMISSION_EARN',
    ];
  }

  static Map<String, String> getOperationTypeLabels() {
    return {
      // التحويلات والمصارفة
      'P2P_TRANSFER_SEND': 'تحويل إلى مشترك (إرسال)',
      'P2P_TRANSFER_RECV': 'استلام تحويل من مشترك',
      'CURRENCY_EXCHANGE': 'مصارفة بين العملات',
      'REMIT_SEND': 'إرسال حوالة خارجية',
      'REMIT_RECV': 'استلام حوالة خارجية',
      
      // المدفوعات والشحن
      'RECHARGE': 'شحن رصيد',
      'BILL_PAYMENT': 'سداد فواتير',
      'PURCHASE_SERVICE': 'شراء خدمات / ألعاب',
      'POS_PAYMENT': 'دفع قيمة مشتريات',
      'POS_SALES_RECEIPT': 'استلام قيمة مشتريات',
      
      // خدمات الوكلاء
      'AGENT_WITHDRAW_REQ': 'سحب نقدي للعميل',
      'AGENT_WITHDRAW_CONFIRM': 'تأكيد تسليم مبلغ سحب',
      'AGENT_DEPOSIT_TO_USER': 'إيداع لمشترك',
      'AGENT_DEPOSIT_TO_POS': 'إيداع لنقطة تجارية',
      
      // الجمعيات / المجموعات
      'COLLECTION_CREATE': 'إنشاء قسمك (مجموعة)',
      'COLLECTION_PAY': 'دفع الفرد لمبلغه في القسمك',
      'COLLECTION_RECEIVE': 'استلام المنشئ للمبلغ المجمّع',
      'COLLECTION_FINAL_PAY': 'دفع مبلغ قسمك (الدفع النهائي)',
      
      // العائلة والحصالات
      'SUB_WALLET_DEPOSIT': 'إيداع لفرد عائلة',
      'SUB_WALLET_RECEIVE': 'استلام إيداع من العائلة',
      'SUB_WALLET_WITHDRAW': 'سحب أو استرداد مبلغ من العائلة',
      'PIGGYBANK_CREATE': 'إنشاء حصالة جديدة',
      'PIGGYBANK_DEPOSIT': 'إيداع مبلغ في حصالة',
      'PIGGYBANK_WITHDRAW': 'كسر الحصالة واستلام المبلغ',
      
      // عمليات عامة
      'REFUND': 'إرجاع باقي / استرداد',
      'COMMISSION_EARN': 'استلام عمولة / أرباح',
    };
  }
}
