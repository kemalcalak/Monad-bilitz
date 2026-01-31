/// Hierarchy level constants based on HKAS implementation
class HierarchyConstants {
  HierarchyConstants._();

  // Hierarchy Levels (lower number = higher authority)
  static const int levelCeo = 1;
  static const int levelDirector = 2;
  static const int levelManager = 3;
  static const int levelEmployee = 4;
  
  // Role identifiers
  static const String roleCeo = 'CEO';
  static const String roleDirector = 'DIRECTOR';
  static const String roleManager = 'MANAGER';
  static const String roleEmployee = 'EMPLOYEE';
  
  // Level names for display
  static const Map<int, String> levelNames = {
    levelCeo: 'CEO',
    levelDirector: 'Director',
    levelManager: 'Manager',
    levelEmployee: 'Employee',
  };
  
  // Level colors for UI
  static const Map<int, int> levelColors = {
    levelCeo: 0xFF9C27B0,      // Purple
    levelDirector: 0xFF2196F3,  // Blue
    levelManager: 0xFF4CAF50,   // Green
    levelEmployee: 0xFF607D8B,  // Blue Grey
  };
  
  /// Get role string from level
  static String getRoleFromLevel(int level) {
    switch (level) {
      case levelCeo:
        return roleCeo;
      case levelDirector:
        return roleDirector;
      case levelManager:
        return roleManager;
      default:
        return roleEmployee;
    }
  }
  
  /// Check if level can approve for target level
  static bool canApprove(int approverLevel, int targetLevel) {
    return approverLevel < targetLevel;
  }
  
  /// Get all levels below a given level
  static List<int> getLevelsBelow(int level) {
    return [levelCeo, levelDirector, levelManager, levelEmployee]
        .where((l) => l > level)
        .toList();
  }
}

/// Contract status constants
class ContractStatus {
  ContractStatus._();
  
  static const String draft = 'DRAFT';
  static const String pendingApproval = 'PENDING_APPROVAL';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
  static const String executed = 'EXECUTED';
  static const String cancelled = 'CANCELLED';
  
  static const Map<String, String> displayNames = {
    draft: 'Draft',
    pendingApproval: 'Pending Approval',
    approved: 'Approved',
    rejected: 'Rejected',
    executed: 'Executed',
    cancelled: 'Cancelled',
  };
  
  static const Map<String, int> statusColors = {
    draft: 0xFF9E9E9E,          // Grey
    pendingApproval: 0xFFFFC107, // Amber
    approved: 0xFF4CAF50,        // Green
    rejected: 0xFFF44336,        // Red
    executed: 0xFF2196F3,        // Blue
    cancelled: 0xFF607D8B,       // Blue Grey
  };
}

/// Signature request status constants
class SignatureStatus {
  SignatureStatus._();
  
  static const String pending = 'PENDING';
  static const String signed = 'SIGNED';
  static const String rejected = 'REJECTED';
  static const String expired = 'EXPIRED';
}
