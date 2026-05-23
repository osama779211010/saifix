class OperationHistoryModel {
  final int id;
  final String operationType;
  final String operationTypeDisplay;
  final String userType;
  final String? relatedUserName;
  final String amount;
  final String currency;
  final String fee;
  final String balanceBefore;
  final String balanceAfter;
  final String description;
  final String referenceNumber;
  final Map<String, dynamic>? extraData;
  final DateTime createdAt;

  OperationHistoryModel({
    required this.id,
    required this.operationType,
    required this.operationTypeDisplay,
    required this.userType,
    this.relatedUserName,
    required this.amount,
    required this.currency,
    required this.fee,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    required this.referenceNumber,
    this.extraData,
    required this.createdAt,
  });

  factory OperationHistoryModel.fromJson(Map<String, dynamic> json) {
    return OperationHistoryModel(
      id: json['id'] ?? 0,
      operationType: json['operation_type'] ?? '',
      operationTypeDisplay: json['operation_type_display'] ?? '',
      userType: json['user_type'] ?? '',
      relatedUserName: json['related_user_name'],
      amount: json['amount']?.toString() ?? '0.00',
      currency: json['currency'] ?? 'YER',
      fee: json['fee']?.toString() ?? '0.00',
      balanceBefore: json['balance_before']?.toString() ?? '0.00',
      balanceAfter: json['balance_after']?.toString() ?? '0.00',
      description: json['description'] ?? '',
      referenceNumber: json['reference_number'] ?? '',
      extraData:
          json['extra_data'] != null
              ? Map<String, dynamic>.from(json['extra_data'])
              : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_type': operationType,
      'operation_type_display': operationTypeDisplay,
      'user_type': userType,
      'related_user_name': relatedUserName,
      'amount': amount,
      'currency': currency,
      'fee': fee,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'description': description,
      'reference_number': referenceNumber,
      'extra_data': extraData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static const List<String> remittanceTypes = [
    'REMIT_SEND_SAIFI',
    'REMIT_RECV_SAIFI',
    'REMIT_SEND',
    'REMIT_RECV',
    'REMIT_RECV_REQ',
    'REMIT_CANCEL',
    'REMIT_MODIFY',
  ];

  /// Returns the appropriate translation key for the reference number label.
  String getReferenceLabelKey() {
    if (remittanceTypes.contains(operationType)) {
      return 'remittance_number_label';
    }
    return 'operation_reference';
  }
}

class OperationHistoryResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<OperationHistoryModel> results;

  OperationHistoryResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory OperationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return OperationHistoryResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
          (json['results'] as List<dynamic>?)
              ?.map(
                (e) =>
                    OperationHistoryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}
