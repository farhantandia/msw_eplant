import 'package:flutter/material.dart';

enum UserRole { operation, maintenance, general }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.operation:
        return 'Operation';
      case UserRole.maintenance:
        return 'Maintenance';
      case UserRole.general:
        return 'General';
    }
  }

  IconData get iconData {
    switch (this) {
      case UserRole.operation:
        return Icons.bolt_rounded;
      case UserRole.maintenance:
        return Icons.handyman_outlined;
      case UserRole.general:
        return Icons.factory_outlined;
    }
  }

  String get icon {
    switch (this) {
      case UserRole.operation:
        return '\u26A1';
      case UserRole.maintenance:
        return '\uD83D\uDD27';
      case UserRole.general:
        return '\uD83C\uDFED';
    }
  }


  String get description {
    switch (this) {
      case UserRole.operation:
        return 'Plant monitoring + Logsheet operator shift';
      case UserRole.maintenance:
        return 'WO reporting + MSW AI knowledge base';
      case UserRole.general:
        return 'Basic Plant Monitoring';
    }
  }

  bool get requiresPassword {
    return true;
  }

  String get tab3Label {
    switch (this) {
      case UserRole.operation:
        return 'Logsheet';
      case UserRole.maintenance:
        return 'Maintenance';
      case UserRole.general:
        return 'OKR';
    }
  }

  // String get tab3Icon {
  //   switch (this) {
  //     case UserRole.operation:
  //       return '\uD83D\uDCCB';
  //     case UserRole.maintenance:
  //       return '\uD83D\uDD27';
  //     case UserRole.general:
  //       return '\uD83C\uDFAF';
  //   }
  // }
}
