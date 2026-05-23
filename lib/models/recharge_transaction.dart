class RechargeTransaction {
  final int id;
  final String referenceNumber;
  final String serviceName;
  final String? offerName;
  final String subscriberNumber;
  final double amount;
  final String status; // PENDING, SUCCESS, FAILED
  final String? responseMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  RechargeTransaction({
    required this.id,
    required this.referenceNumber,
    required this.serviceName,
    this.offerName,
    required this.subscriberNumber,
    required this.amount,
    required this.status,
    this.responseMessage,
    required this.createdAt,
    this.completedAt,
  });

  factory RechargeTransaction.fromJson(Map<String, dynamic> json) {
    return RechargeTransaction(
      id: json['id'] as int,
      referenceNumber: json['reference_number'] as String,
      serviceName: json['service_name'] as String,
      offerName: json['offer_name'] as String?,
      subscriberNumber: json['subscriber_number'] as String,
      amount: double.parse(json['amount'].toString()),
      status: json['status'] as String,
      responseMessage: json['response_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'service_name': serviceName,
      'offer_name': offerName,
      'subscriber_number': subscriberNumber,
      'amount': amount,
      'status': status,
      'response_message': responseMessage,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  bool get isSuccess => status == 'SUCCESS';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';

  String get statusLabel {
    switch (status) {
      case 'SUCCESS':
        return 'ناجحة';
      case 'PENDING':
        return 'معلقة';
      case 'FAILED':
        return 'فاشلة';
      default:
        return status;
    }
  }
}
