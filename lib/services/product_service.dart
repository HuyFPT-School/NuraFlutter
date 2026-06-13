import '../config/api_config.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _api = ApiClient();

  Future<List<ProductModel>> getProducts() async {
    final response = await _api.get(ApiConfig.products);
    final data = response.data;
    List list = data is List ? data : (data['data'] ?? data['products'] ?? []);
    return list.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await _api.get(ApiConfig.productById(id));
    final data = response.data;
    final product = data is Map<String, dynamic> && data.containsKey('data') ? data['data'] : data;
    return ProductModel.fromJson(product);
  }

  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final response = await _api.get(ApiConfig.productsByCategory(categoryId));
    final data = response.data;
    List list = data is List ? data : (data['data'] ?? []);
    return list.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getProductsByBrand(String brandId) async {
    final response = await _api.get(ApiConfig.productsByBrand(brandId));
    final data = response.data;
    List list = data is List ? data : (data['data'] ?? []);
    return list.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _api.get(ApiConfig.categories);
    final data = response.data;
    List list = data is List ? data : (data['data'] ?? data['categories'] ?? []);
    return list.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<BrandModel>> getBrands() async {
    final response = await _api.get(ApiConfig.brands);
    final data = response.data;
    List list = data is List ? data : (data['data'] ?? data['brands'] ?? []);
    return list.map((e) => BrandModel.fromJson(e)).toList();
  }

  Future<void> addComment(String productId, int rating, String content) async {
    await _api.post(ApiConfig.addComment(productId), data: {'rating': rating, 'content': content});
  }
}
