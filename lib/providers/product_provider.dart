import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../services/product_service.dart';
import '../services/api_client.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  String? _selectedCategoryId;
  String _searchQuery = '';

  List<ProductModel> get products => _filteredProducts;
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getProducts(),
        _service.getCategories(),
        _service.getBrands(),
      ]);
      _products = results[0] as List<ProductModel>;
      _categories = results[1] as List<CategoryModel>;
      _brands = results[2] as List<BrandModel>;
      _applyFilters();
    } on DioException catch (e) {
      _error = ApiClient.getErrorMessage(e);
    } catch (e) {
      _error = 'Không thể tải sản phẩm.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void filterByCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((p) {
      bool matchCategory = true;
      bool matchSearch = true;

      if (_selectedCategoryId != null) {
        String catId = '';
        if (p.category is CategoryModel) catId = (p.category as CategoryModel).id;
        else if (p.category is String) catId = p.category;
        else if (p.category is Map) catId = p.category['_id'] ?? p.category['id'] ?? '';
        matchCategory = catId == _selectedCategoryId;
      }

      if (_searchQuery.isNotEmpty) {
        matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return matchCategory && matchSearch;
    }).toList();
  }

  Future<void> loadProductDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _service.getProductById(id);
    } on DioException catch (e) {
      _error = ApiClient.getErrorMessage(e);
    } catch (e) {
      _error = 'Không thể tải chi tiết sản phẩm.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addComment(String productId, int rating, String content) async {
    try {
      await _service.addComment(productId, rating, content);
      await loadProductDetail(productId);
    } catch (_) {}
  }
}
