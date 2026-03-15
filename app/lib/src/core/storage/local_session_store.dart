import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/auth_state.dart';
import '../../shared/models/clothing_item.dart';

class LocalSessionStore {
  static const _guestAuthKey = 'guest_auth_state_v1';
  static const _localClosetKey = 'local_closet_items_v1';

  Future<AuthStateSnapshot?> loadGuestAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestAuthKey);
    if (raw == null || raw.isEmpty) return null;
    return AuthStateSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveGuestAuthState(AuthStateSnapshot state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestAuthKey, jsonEncode(state.toJson()));
  }

  Future<void> clearGuestAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestAuthKey);
  }

  Future<List<ClothingItem>> loadLocalClosetItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localClosetKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((row) => ClothingItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocalClosetItems(List<ClothingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localClosetKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
