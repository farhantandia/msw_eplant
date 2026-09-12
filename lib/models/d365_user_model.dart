class D365UserSession {
  final String employeeCode;
  final String employeeName;
  final String department;
  final String defaultCostCenter;
  final DateTime loginTime;

  D365UserSession({
    required this.employeeCode,
    required this.employeeName,
    required this.department,
    required this.defaultCostCenter,
    required this.loginTime,
  });

  String get displayName => '$employeeCode - $employeeName';

  factory D365UserSession.fromJson(Map<String, dynamic> json) {
    return D365UserSession(
      employeeCode: json['employeeCode']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      defaultCostCenter: json['defaultCostCenter']?.toString() ?? '6100DB401 - MSW_Maintenance - Mechanical',
      loginTime: json['loginTime'] != null
          ? DateTime.tryParse(json['loginTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeCode': employeeCode,
      'employeeName': employeeName,
      'department': department,
      'defaultCostCenter': defaultCostCenter,
      'loginTime': loginTime.toIso8601String(),
    };
  }
}
