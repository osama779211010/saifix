class GroupCollection {
  final int id;
  final String ownerName;
  final double totalAmount;
  final String currency;
  final String divisionType;
  final String status;
  final String? purpose;
  final DateTime createdAt;
  final List<CollectionMember> members;
  final double paidTotal;
  final double remainingTotal;

  GroupCollection({
    required this.id,
    required this.ownerName,
    required this.totalAmount,
    required this.currency,
    required this.divisionType,
    required this.status,
    this.purpose,
    required this.createdAt,
    this.members = const [],
    this.paidTotal = 0,
    this.remainingTotal = 0,
  });

  factory GroupCollection.fromJson(Map<String, dynamic> json) {
    return GroupCollection(
      id: json['collection_id'] ?? json['id'] ?? 0,
      ownerName: json['owner_name'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'YER',
      divisionType: json['division_type'] ?? 'EQUAL',
      status: (json['overall_status'] ?? json['status'] ?? 'PENDING').toString().toUpperCase(),
      purpose: json['purpose'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      members: (json['members'] as List? ?? [])
          .map((m) => CollectionMember.fromJson(m))
          .toList(),
      paidTotal: double.tryParse(json['summary']?['paid_total']?.toString() ?? 
                 json['paid_total']?.toString() ?? '0') ?? 0.0,
      remainingTotal: double.tryParse(json['summary']?['remaining_total']?.toString() ?? 
                      json['remaining_total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CollectionMember {
  final String name;
  final String? phone;
  final double requestedAmount;
  final String status;
  final DateTime? paidAt;

  CollectionMember({
    required this.name,
    this.phone,
    required this.requestedAmount,
    required this.status,
    this.paidAt,
  });

  factory CollectionMember.fromJson(Map<String, dynamic> json) {
    return CollectionMember(
      name: json['name'] ?? '',
      phone: json['phone'] ?? json['phone_number'],
      requestedAmount: double.tryParse(json['requested_amount']?.toString() ?? '0') ?? 0.0,
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
    );
  }
}

class PendingCollectionRequest {
  final int id; // This is member_id in backend for responding
  final int collectionId;
  final String ownerName;
  final String? purpose;
  final double requestedAmount;
  final String currency;
  final String status;
  final DateTime createdAt;

  PendingCollectionRequest({
    required this.id,
    required this.collectionId,
    required this.ownerName,
    this.purpose,
    required this.requestedAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory PendingCollectionRequest.fromJson(Map<String, dynamic> json) {
    return PendingCollectionRequest(
      id: json['id'] ?? 0,
      collectionId: json['collection_id'] ?? 0,
      ownerName: json['owner_name'] ?? '',
      purpose: json['purpose'],
      requestedAmount: double.tryParse(json['requested_amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'YER',
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
