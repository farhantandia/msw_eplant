class MaterialIssueLineItem {
  final String itemNumber;
  final String itemName;
  final double quantity;
  final String unitType;
  final double availableStock;
  final String? location;

  MaterialIssueLineItem({
    required this.itemNumber,
    required this.itemName,
    required this.quantity,
    required this.unitType,
    required this.availableStock,
    this.location,
  });

  factory MaterialIssueLineItem.fromJson(Map<String, dynamic> json) {
    return MaterialIssueLineItem(
      itemNumber: json['itemNumber']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitType: json['unitType']?.toString() ?? 'PCS',
      availableStock: (json['availableStock'] as num?)?.toDouble() ?? 0.0,
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemNumber': itemNumber,
      'itemName': itemName,
      'quantity': quantity,
      'unitType': unitType,
      'availableStock': availableStock,
      if (location != null) 'location': location,
    };
  }

  MaterialIssueLineItem copyWith({
    String? itemNumber,
    String? itemName,
    double? quantity,
    String? unitType,
    double? availableStock,
    String? location,
  }) {
    return MaterialIssueLineItem(
      itemNumber: itemNumber ?? this.itemNumber,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitType: unitType ?? this.unitType,
      availableStock: availableStock ?? this.availableStock,
      location: location ?? this.location,
    );
  }
}

class MaterialIssueRequest {
  final String transactionId;
  final String woNumber;
  final String warehouseLocation;
  final String activity;
  final String costCenter;
  final DateTime transactionDate;
  final String remarks;
  final String submittedBy;
  final List<MaterialIssueLineItem> items;
  final String status;
  final String? d365JournalNo;

  MaterialIssueRequest({
    required this.transactionId,
    required this.woNumber,
    required this.warehouseLocation,
    required this.activity,
    required this.costCenter,
    required this.transactionDate,
    this.remarks = '',
    required this.submittedBy,
    required this.items,
    this.status = 'Submitted',
    this.d365JournalNo,
  });

  int get totalItemCount => items.length;

  double get totalQuantity =>
      items.fold(0.0, (sum, item) => sum + item.quantity);

  /// Mengambil hanya kode activity (misal: 6100AC5403) untuk dikirim ke API D365
  String get activityCode {
    if (activity.contains(' - ')) {
      return activity.split(' - ')[0].trim();
    }
    return activity.trim();
  }

  /// Mengambil hanya kode unit (misal: 6100DB401) untuk dikirim ke API D365
  String get costCenterCode {
    if (costCenter.contains(' - ')) {
      return costCenter.split(' - ')[0].trim();
    }
    return costCenter.trim();
  }

  /// Mengambil hanya kode employee / request by (misal: 61000003) untuk dikirim ke API D365
  String get submittedByCode {
    if (submittedBy.contains(' - ')) {
      return submittedBy.split(' - ')[0].trim();
    }
    return submittedBy.trim();
  }

  factory MaterialIssueRequest.fromJson(Map<String, dynamic> json) {
    return MaterialIssueRequest(
      transactionId: json['transactionId']?.toString() ?? '',
      woNumber: json['woNumber']?.toString() ?? '',
      warehouseLocation: json['warehouseLocation']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      costCenter: json['costCenter']?.toString() ?? '',
      transactionDate: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      remarks: json['remarks']?.toString() ?? '',
      submittedBy: json['submittedBy']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  MaterialIssueLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'Submitted',
      d365JournalNo: json['d365JournalNo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'woNumber': woNumber,
      'warehouseLocation': warehouseLocation,
      'activity': activity,
      'costCenter': costCenter,
      'transactionDate': transactionDate.toIso8601String(),
      'remarks': remarks,
      'submittedBy': submittedBy,
      'items': items.map((e) => e.toJson()).toList(),
      'status': status,
      if (d365JournalNo != null) 'd365JournalNo': d365JournalNo,
    };
  }

  /// Payload resmi untuk pengiriman ke endpoint D365 (menggunakan kode resmi)
  Map<String, dynamic> toD365Payload() {
    return {
      'transactionId': transactionId,
      'woNumber': woNumber,
      'warehouseLocation': warehouseLocation,
      'activity': activityCode, // Mengirim kode dimension value (misal: 6100AC5403)
      'costCenter': costCenterCode, // Mengirim kode unit (misal: 6100DB401)
      'requestBy': submittedByCode, // Mengirim kode employee (misal: 61000003)
      'submittedBy': submittedByCode,
      'employeeCode': submittedByCode,
      'transactionDate': transactionDate.toIso8601String(),
      'remarks': remarks,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
