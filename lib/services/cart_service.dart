import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/menu.dart';

class CartService {
  static const String _cartKey = 'cart_items';

  // Simpan keranjang ke local storage
  static Future<void> saveCart(List<Menu> cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = cart.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, json.encode(cartJson));
      print('✅ Cart saved with ${cart.length} items');
    } catch (e) {
      print('❌ Error saving cart: $e');
    }
  }

  // Load keranjang dari local storage
  static Future<List<Menu>> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(cartJson);
        final List<Menu> loadedCart = jsonList.map((json) => Menu.fromJson(json)).toList();
        print('✅ Cart loaded with ${loadedCart.length} items');
        return loadedCart;
      }
    } catch (e) {
      print('❌ Error loading cart: $e');
    }
    return [];
  }

  // Clear keranjang
  static Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      print('✅ Cart cleared');
    } catch (e) {
      print('❌ Error clearing cart: $e');
    }
  }
}