import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 0;
  final int _pageSize = 12;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLastPage = false;

  // Filter params
  String _keyword = '';
  int? _selectedCategoryId;
  int? _selectedBrandId;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'createdAt';
  String _sortDir = 'desc';

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => !_isLastPage;

  String get keyword => _keyword;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedBrandId => _selectedBrandId;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String get sortBy => _sortBy;
  String get sortDir => _sortDir;

  bool _shouldFocusSearch = false;
  bool get shouldFocusSearch => _shouldFocusSearch;

  void requestSearchFocus() {
    _shouldFocusSearch = true;
    notifyListeners();
  }

  void consumeSearchFocus() {
    _shouldFocusSearch = false;
  }

  bool get hasActiveFilters =>
      _keyword.isNotEmpty ||
      _selectedCategoryId != null ||
      _selectedBrandId != null ||
      _minPrice != null ||
      _maxPrice != null;

  Future<void> initialize() async {
    await Future.wait([
      fetchCategories(),
      fetchBrands(),
      fetchProducts(reset: true),
    ]);
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await ProductService.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchBrands() async {
    try {
      _brands = await ProductService.getBrands();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      if (_isLoadingMore || _isLastPage) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final pageResult = await ProductService.getProducts(
        page: _currentPage,
        size: _pageSize,
        keyword: _keyword,
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );

      if (reset) {
        _products = pageResult.content;
      } else {
        _products.addAll(pageResult.content);
      }

      _totalPages = pageResult.totalPages;
      _totalElements = pageResult.totalElements;
      _isLastPage = pageResult.last;
      _currentPage++;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setKeyword(String value) {
    if (_keyword == value) return;
    _keyword = value;
    fetchProducts(reset: true);
  }

  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    fetchProducts(reset: true);
  }

  void setBrand(int? brandId) {
    _selectedBrandId = brandId;
    fetchProducts(reset: true);
  }

  void setPriceFilter(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    fetchProducts(reset: true);
  }

  void setSorting(String sortBy, String sortDir) {
    _sortBy = sortBy;
    _sortDir = sortDir;
    fetchProducts(reset: true);
  }

  Future<void> applyFilters({
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortDir,
  }) async {
    _selectedCategoryId = categoryId;
    _selectedBrandId = brandId;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    if (sortBy != null) _sortBy = sortBy;
    if (sortDir != null) _sortDir = sortDir;
    await fetchProducts(reset: true);
  }

  void resetFilters() {
    _keyword = '';
    _selectedCategoryId = null;
    _selectedBrandId = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = 'createdAt';
    _sortDir = 'desc';
    fetchProducts(reset: true);
  }

  void clearFilters() => resetFilters();
}
