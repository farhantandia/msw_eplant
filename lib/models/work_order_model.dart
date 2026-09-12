class WorkOrder {
  final String woNumber;
  final String title;
  final String equipment;
  final String activity;
  final String costCenter;
  final String warehouseLocation;
  final String status;
  final DateTime? targetDate;

  WorkOrder({
    required this.woNumber,
    required this.title,
    required this.equipment,
    required this.activity,
    required this.costCenter,
    this.warehouseLocation = 'MAINSTORE',
    this.status = 'In Progress',
    this.targetDate,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      woNumber: json['woNumber']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      equipment: json['equipment']?.toString() ?? '',
      activity: json['activity']?.toString() ?? 'Corrective Maintenance',
      costCenter: json['costCenter']?.toString() ?? '6100DB401 - MSW_Maintenance - Mechanical',
      warehouseLocation: json['warehouseLocation']?.toString() ?? 'MAINSTORE',
      status: json['status']?.toString() ?? 'In Progress',
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'woNumber': woNumber,
      'title': title,
      'equipment': equipment,
      'activity': activity,
      'costCenter': costCenter,
      'warehouseLocation': warehouseLocation,
      'status': status,
      if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
    };
  }
}
