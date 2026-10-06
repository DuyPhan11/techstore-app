import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_colors.dart';
import '../services/admin_service.dart';
import '../utils/toast_helper.dart';

class ProductImagePickerWidget extends StatefulWidget {
  final TextEditingController imageUrlController;
  final VoidCallback? onImageChanged;

  const ProductImagePickerWidget({
    super.key,
    required this.imageUrlController,
    this.onImageChanged,
  });

  @override
  State<ProductImagePickerWidget> createState() => _ProductImagePickerWidgetState();
}

class _ProductImagePickerWidgetState extends State<ProductImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  Uint8List? _localPreviewBytes;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _localPreviewBytes = bytes;
        _isUploading = true;
      });

      // Upload lên backend
      final uploadedUrl = await AdminService.uploadImageBytes(
        bytes: bytes,
        fileName: pickedFile.name,
      );

      if (mounted) {
        setState(() {
          widget.imageUrlController.text = uploadedUrl;
          _isUploading = false;
        });
        widget.onImageChanged?.call();
        ToastHelper.showSuccess(context, 'Tải ảnh lên máy chủ thành công!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ToastHelper.showError(context, 'Lỗi tải ảnh lên: $e');
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Chọn nguồn hình ảnh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                ),
                title: const Text('Chọn ảnh từ thư viện máy'),
                subtitle: const Text('Hình ảnh có sẵn trong bộ nhớ thiết bị', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                ),
                title: const Text('Chụp ảnh từ máy ảnh'),
                subtitle: const Text('Chụp trực tiếp từ camera của máy', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _localPreviewBytes = null;
      widget.imageUrlController.clear();
    });
    widget.onImageChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = widget.imageUrlController.text.trim();
    final hasImage = _localPreviewBytes != null || currentUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Khung hiển thị và chọn ảnh
        Center(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasImage ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Preview ảnh
                      if (_localPreviewBytes != null)
                        Image.memory(
                          _localPreviewBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                        )
                      else if (currentUrl.isNotEmpty)
                        Image.network(
                          currentUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, size: 42, color: Colors.grey),
                              SizedBox(height: 6),
                              Text('Không thể tải ảnh từ URL', style: TextStyle(fontSize: 12, color: Colors.red)),
                            ],
                          ),
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa có ảnh sản phẩm',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhấn nút bên dưới để chọn ảnh từ thiết bị',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ),

                      // Overlay khi đang tải lên
                      if (_isUploading)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                SizedBox(height: 10),
                                Text(
                                  'Đang tải ảnh lên...',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Nút xóa ảnh ở góc
                      if (hasImage && !_isUploading)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _clearImage,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Các nút thao tác
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(
                        hasImage ? 'Đổi ảnh từ máy' : 'Chọn ảnh từ máy',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isUploading ? null : _showImageSourcePicker,
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Bỏ ảnh', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isUploading ? null : _clearImage,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Nhập trực tiếp URL nếu cần
        TextFormField(
          controller: widget.imageUrlController,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Hoặc dán link URL hình ảnh',
            hintText: 'https://cdn.example.com/image.jpg',
            prefixIcon: const Icon(Icons.link, size: 18),
            isDense: true,
            suffixIcon: widget.imageUrlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _clearImage();
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (_) {
            setState(() {
              _localPreviewBytes = null;
            });
            widget.onImageChanged?.call();
          },
        ),
      ],
    );
  }
}
