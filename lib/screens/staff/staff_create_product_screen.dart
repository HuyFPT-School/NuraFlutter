import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/brand_model.dart';
import '../../services/product_service.dart';

class StaffCreateProductScreen extends StatefulWidget {
  const StaffCreateProductScreen({super.key});

  @override
  State<StaffCreateProductScreen> createState() => _StaffCreateProductScreenState();
}

class _StaffCreateProductScreenState extends State<StaffCreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _picker = ImagePicker();

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _weightController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  final _storageController = TextEditingController();
  final _usageController = TextEditingController();
  final _warningController = TextEditingController();
  final _tagsController = TextEditingController();

  // Dropdown selections
  String? _selectedCategory;
  String? _selectedBrand;

  // Date selection fields
  DateTime? _manufactureDate;
  DateTime? _expiryDate;

  // UI state
  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _showOptionalFields = false;
  String? _errorMessage;

  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    _manufacturerController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    _storageController.dispose();
    _usageController.dispose();
    _warningController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    try {
      final results = await Future.wait([
        _productService.getCategories(),
        _productService.getBrands(),
      ]);
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _brands = results[1] as List<BrandModel>;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh mục hoặc thương hiệu. Vui lòng quay lại.';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _isUploadingImage = true;
        _errorMessage = null;
      });

      final url = await _productService.uploadProductImage(file.path);

      setState(() {
        _imageUrlController.text = url;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh lên thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _errorMessage = 'Tải ảnh thất bại: ${e.toString()}';
      });
    }
  }

  void _showImagePickerSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Chọn ảnh từ Thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final controller = TextEditingController(text: _imageUrlController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Nhập URL ảnh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _imageUrlController.text = controller.text.trim();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isManufacture) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isManufacture) {
          _manufactureDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrlController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng chọn hoặc nhập hình ảnh sản phẩm';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final productData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'brand': _selectedBrand,
        'quantity': int.parse(_quantityController.text),
        'weight': double.parse(_weightController.text),
        'manufacturer': _manufacturerController.text.trim(),
        'imageUrl': [_imageUrlController.text.trim()],
      };

      if (_descriptionController.text.trim().isNotEmpty) {
        productData['description'] = _descriptionController.text.trim();
      }
      if (_ageController.text.trim().isNotEmpty) {
        productData['appropriateAge'] = _ageController.text.trim();
      }
      if (_manufactureDate != null) {
        productData['manufacture'] = DateFormat('yyyy-MM-dd').format(_manufactureDate!);
      }
      if (_expiryDate != null) {
        productData['expiry'] = DateFormat('yyyy-MM-dd').format(_expiryDate!);
      }
      if (_storageController.text.trim().isNotEmpty) {
        productData['storageInstructions'] = _storageController.text.trim();
      }
      if (_usageController.text.trim().isNotEmpty) {
        productData['instructionsForUse'] = _usageController.text.trim();
      }
      if (_warningController.text.trim().isNotEmpty) {
        productData['warning'] = _warningController.text.trim();
      }
      if (_tagsController.text.trim().isNotEmpty) {
        productData['tags'] = _tagsController.text.trim();
      }

      await _productService.createProduct(productData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sản phẩm "${_nameController.text.trim()}" đã được tạo!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate successful creation
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo sản phẩm mới'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) _buildErrorBanner(),

            // Image Preview & Upload Card
            _buildImageCard(),
            const SizedBox(height: 16),

            // General Info Card
            _buildGeneralInfoCard(),
            const SizedBox(height: 16),

            // Dropdowns (Brand, Category) Card
            _buildSelectionCard(),
            const SizedBox(height: 16),

            // Toggle Optional Fields Button
            _buildOptionalToggler(),

            if (_showOptionalFields) ...[
              const SizedBox(height: 12),
              _buildOptionalFieldsCard(),
            ],

            const SizedBox(height: 24),

            // Save Buttons
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    final imageText = _imageUrlController.text.trim();
    final hasImage = imageText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình ảnh sản phẩm *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Preview box
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          imageText,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: AppColors.error, size: 36),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 36),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isUploadingImage)
                      const Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          SizedBox(width: 8),
                          Text('Đang tải ảnh lên...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      )
                    else ...[
                      ElevatedButton.icon(
                        onPressed: _showImagePickerSourceSheet,
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _showUrlInputDialog,
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Nhập URL ảnh', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    if (hasImage) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _imageUrlController.clear()),
                        child: const Text('Xóa ảnh', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin chung', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Divider(height: 20),
          _buildTextField(
            controller: _nameController,
            label: 'Tên sản phẩm *',
            hint: 'Nhập tên sữa, ví dụ: Sữa Meiji Gold',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên sản phẩm';
              if (v.trim().length < 3) return 'Tên phải có tối thiểu 3 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Giá bán (VND) *',
                  hint: '250000',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập giá';
                    final p = double.tryParse(v);
                    if (p == null || p <= 0) return 'Giá bán phải > 0';
                    if (p < 1000) return 'Giá tối thiểu 1.000đ';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _quantityController,
                  label: 'Số lượng kho *',
                  hint: '50',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nhập số lượng';
                    final q = int.tryParse(v);
                    if (q == null || q < 0) return 'Không được âm';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Trọng lượng (gam) *',
                  hint: '900',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nhập trọng lượng';
                    final w = double.tryParse(v);
                    if (w == null || w <= 0) return 'Trọng lượng > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _manufacturerController,
                  label: 'Nhà sản xuất *',
                  hint: 'Meiji Co., Ltd',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nhập tên NSX';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh mục & Thương hiệu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Divider(height: 20),
          _buildDropdownField<CategoryModel>(
            value: _selectedCategory,
            label: 'Danh mục *',
            items: _categories,
            itemLabel: (c) => c.name,
            itemId: (c) => c.id,
            onChanged: (val) => setState(() => _selectedCategory = val),
            validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
          ),
          const SizedBox(height: 12),
          _buildDropdownField<BrandModel>(
            value: _selectedBrand,
            label: 'Thương hiệu *',
            items: _brands,
            itemLabel: (b) => b.name,
            itemId: (b) => b.id,
            onChanged: (val) => setState(() => _selectedBrand = val),
            validator: (v) => v == null ? 'Vui lòng chọn thương hiệu' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalToggler() {
    return InkWell(
      onTap: () => setState(() => _showOptionalFields = !_showOptionalFields),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: cardDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Thông tin chi tiết (Không bắt buộc)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            Icon(
              _showOptionalFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalFieldsCard() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final mDateText = _manufactureDate != null ? dateFormat.format(_manufactureDate!) : 'Chọn ngày';
    final eDateText = _expiryDate != null ? dateFormat.format(_expiryDate!) : 'Chọn ngày';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _descriptionController,
            label: 'Mô tả sản phẩm',
            hint: 'Nhập thông tin mô tả sữa...',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _ageController,
            label: 'Độ tuổi thích hợp',
            hint: 'Ví dụ: 0 - 6 tháng tuổi',
          ),
          const SizedBox(height: 12),

          // Date Selectors
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ngày sản xuất', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
                      label: Text(mDateText, style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _manufactureDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hạn sử dụng', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
                      label: Text(eDateText, style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _expiryDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _storageController,
            label: 'Hướng dẫn bảo quản',
            hint: 'Bảo quản nơi khô ráo thoáng mát...',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _usageController,
            label: 'Hướng dẫn sử dụng',
            hint: 'Pha 5 thìa sữa với 200ml nước ấm...',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _warningController,
            label: 'Cảnh báo an toàn',
            hint: 'Không sử dụng nếu hộp bị biến dạng...',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _tagsController,
            label: 'Tình trạng / Tags',
            hint: 'Mới về, Bán chạy, v.v.',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hủy bỏ', style: TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Tạo sản phẩm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String? value,
    required String label,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) itemId,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          hint: const Text('Chọn một mục', style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: itemId(item),
              child: Text(itemLabel(item), style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
