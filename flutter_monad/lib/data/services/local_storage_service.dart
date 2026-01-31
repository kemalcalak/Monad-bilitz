import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for local storage operations (JSON read/write)
class LocalStorageService {
  static const String _hierarchyKey = 'hierarchy_data';
  static const String _usersKey = 'registered_users';
  
  /// Load hierarchy data from assets (initial) or SharedPreferences (if modified)
  Future<Map<String, dynamic>> loadHierarchyData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_hierarchyKey);
    
    if (savedData != null) {
      return json.decode(savedData) as Map<String, dynamic>;
    }
    
    // Load from assets if no saved data
    final assetData = await rootBundle.loadString('assets/sample_hierarchy_data.json');
    return json.decode(assetData) as Map<String, dynamic>;
  }
  
  /// Save hierarchy data to SharedPreferences
  Future<void> saveHierarchyData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hierarchyKey, json.encode(data));
  }
  
  /// Get all users from hierarchy
  Future<List<Map<String, dynamic>>> getUsers() async {
    final data = await loadHierarchyData();
    final nodes = data['hierarchy_nodes'] as List<dynamic>?;
    return nodes?.cast<Map<String, dynamic>>() ?? [];
  }
  
  /// Find user by ID
  Future<Map<String, dynamic>?> findUserById(String id) async {
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u['id'] == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Add new user to hierarchy
  Future<void> addUser(Map<String, dynamic> newUser) async {
    final data = await loadHierarchyData();
    final nodes = (data['hierarchy_nodes'] as List<dynamic>?) ?? [];
    nodes.add(newUser);
    data['hierarchy_nodes'] = nodes;
    await saveHierarchyData(data);
  }
  
  /// Generate random wallet address
  String generateWalletAddress() {
    final random = Random();
    final chars = '0123456789abcdef';
    final address = StringBuffer('0x');
    for (int i = 0; i < 40; i++) {
      address.write(chars[random.nextInt(chars.length)]);
    }
    return address.toString();
  }
  
  /// Get random parent from existing users
  Future<Map<String, dynamic>?> getRandomParent() async {
    final users = await getUsers();
    if (users.isEmpty) return null;
    
    // Filter users that can be parents (level < 3)
    final potentialParents = users.where((u) => ((u['level'] as int?) ?? 0) < 3).toList();
    if (potentialParents.isEmpty) return users[Random().nextInt(users.length)];
    
    return potentialParents[Random().nextInt(potentialParents.length)];
  }
  
  /// Save registered user credentials
  Future<void> saveUserCredentials(String id, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final Map<String, dynamic> users = usersJson != null 
        ? json.decode(usersJson) as Map<String, dynamic>
        : {};
    
    users[id] = password;
    await prefs.setString(_usersKey, json.encode(users));
  }
  
  /// Verify user credentials
  Future<bool> verifyCredentials(String id, String password) async {
    // Default password is same as ID for existing users
    final user = await findUserById(id);
    if (user == null) return false;
    
    // Check if user has custom password
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final users = json.decode(usersJson) as Map<String, dynamic>;
      if (users.containsKey(id)) {
        return users[id] == password;
      }
    }
    
    // Default: password = id
    return password == id;
  }
  
  /// Save current user session
  Future<void> saveCurrentUser(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', id);
  }
  
  /// Get current user session
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id');
  }
  
  /// Clear current user session
  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }
}
