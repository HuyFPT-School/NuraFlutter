import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> _cartItems = [];
  static const String _cartKey = 'cart';

  List<CartItemModel> get cartItems => _cartItems;
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get shippingFee => totalPrice > 500000 ? 0 : 30000;
  double get grandTotal => totalPrice + shippingFee;
  List<CartItemModel> get regularItems => _cartItems.where((i) => !i.isPreOrder).toList();
  List<CartItemModel> get preOrderItems => _cartItems.where((i) => i.isPreOrder).toList();
  bool get hasOnlyPreOrder => _cartItems.isNotEmpty && _cartItems.every((i) => i.isPreOrder);
  bool get isEmpty => _cartItems.isEmpty;

  Future<void> init() async {
    await _loadCart();
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((i) => i.productId == product.id);
    final isPreOrder = product.isOutOfStock && product.allowPreOrder;
    final maxQty = isPreOrder ? product.maxPreOrderQuantity : product.quantity;

    if (existingIndex >= 0) {
      final item = _cartItems[existingIndex];
      item.quantity = (item.quantity + quantity).clamp(1, maxQty);
    } else {
      _cartItems.add(CartItemModel(
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.firstImage,
        quantity: quantity.clamp(1, maxQty),
        availableStock: maxQty,
        isPreOrder: isPreOrder,
      ));
    }
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((i) => i.productId == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _cartItems.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      _cartItems[index].quantity = newQuantity.clamp(1, _cartItems[index].availableStock);
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cartItems.map((e) => e.toJson()).toList();
    await prefs.setString(_cartKey, json.encode(jsonList));
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cartKey);
    if (jsonStr != null) {
      final List list = json.decode(jsonStr);
      _cartItems = list.map((e) => CartItemModel.fromJson(e)).toList();
    }
  }
}
