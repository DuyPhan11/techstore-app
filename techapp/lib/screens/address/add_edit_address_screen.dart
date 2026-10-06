import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../services/location_service.dart';
import '../../utils/toast_helper.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _wardController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;

  bool _isDefault = false;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _nameController = TextEditingController(text: addr?.recipientName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _streetController = TextEditingController(text: addr?.streetAddress ?? '');
    _wardController = TextEditingController(text: addr?.ward ?? '');
    _districtController = TextEditingController(text: addr?.district ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Automatically fetch current GPS location and fill address
  Future<void> _handleGetGpsLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      final place = await LocationService.reverseGeocode(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          if (place.city.isNotEmpty) _cityController.text = place.city;
          if (place.district.isNotEmpty) _districtController.text = place.district;
          if (place.ward.isNotEmpty) _wardController.text = place.ward;
          if (place.streetAddress.isNotEmpty) _streetController.text = place.streetAddress;
        });

        ToastHelper.showSuccess(context, 'Đã lấy vị trí GPS thành công!');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  /// Search real physical locations in Vietnam
  void _openPlaceSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlaceSearchSheet(
        onSelectPlace: (place) {
          setState(() {
            if (place.city.isNotEmpty) _cityController.text = place.city;
            if (place.district.isNotEmpty) _districtController.text = place.district;
            if (place.ward.isNotEmpty) _wardController.text = place.ward;
            if (place.streetAddress.isNotEmpty) _streetController.text = place.streetAddress;
          });
          ToastHelper.showSuccess(context, 'Đã chọn địa điểm thực tế!');
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'recipientName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'streetAddress': _streetController.text.trim(),
      'ward': _wardController.text.trim(),
      'district': _districtController.text.trim(),
      'city': _cityController.text.trim(),
      'isDefault': _isDefault,
    };

    final provider = Provider.of<AddressProvider>(context, listen: false);

    try {
      if (_isEditing) {
        await provider.updateAddress(widget.address!.id, data);
        if (mounted) {
          ToastHelper.showSuccess(context, 'Cập nhật địa chỉ thành công');
          Navigator.pop(context);
        }
      } else {
        await provider.createAddress(data);
        if (mounted) {
          ToastHelper.showSuccess(context, 'Thêm địa chỉ mới thành công');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ nhận hàng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Smart GPS / Search Buttons Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assistant_direction_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Định vị vị trí thông minh',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tự động điền nhanh địa chỉ thực tế thông qua GPS thiết bị hoặc tìm kiếm địa điểm thực tế trên bản đồ.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 16),
                            label: Text(
                              _isGettingLocation ? 'Đang lấy GPS...' : 'Lấy vị trí GPS',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isGettingLocation ? null : _handleGetGpsLocation,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.search_rounded, size: 16),
                            label: const Text(
                              'Tìm địa điểm thực',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _openPlaceSearchModal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Thông tin người nhận',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên người nhận *',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên người nhận' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại liên hệ *',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                  final reg = RegExp(r'^(0[3|5|7|8|9])([0-9]{8})$');
                  if (!reg.hasMatch(val.trim())) {
                    return 'Số điện thoại không hợp lệ (10 số, đầu 03/05/07/08/09)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Địa chỉ chi tiết',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Tỉnh / Thành phố *',
                  hintText: 'Ví dụ: TP. Hồ Chí Minh, Hà Nội, Đà Nẵng...',
                  prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập Tỉnh / Thành phố' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'Quận / Huyện',
                        hintText: 'Quận 1, Cầu Giấy...',
                        prefixIcon: Icon(Icons.map_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _wardController,
                      decoration: const InputDecoration(
                        labelText: 'Phường / Xã',
                        hintText: 'Phường Bến Nghé...',
                        prefixIcon: Icon(Icons.holiday_village_outlined, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Số nhà, tên đường *',
                  hintText: 'Ví dụ: 123 Nguyễn Huệ, Tòa nhà Landmark 81...',
                  prefixIcon: Icon(Icons.home_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập số nhà và tên đường' : null,
              ),
              const SizedBox(height: 16),

              // Default Switch
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đặt làm địa chỉ mặc định', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Hệ thống sẽ ưu tiên chọn địa chỉ này khi bạn đặt hàng', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                value: _isDefault,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ nhận hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  final Function(PlaceResult) onSelectPlace;

  const _PlaceSearchSheet({required this.onSelectPlace});

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final TextEditingController _queryController = TextEditingController();
  List<PlaceResult> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  Future<void> _handleSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await LocationService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tìm kiếm: $e';
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tìm kiếm địa điểm thực tế tại Việt Nam',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhập tên tòa nhà, địa danh, trường học, bệnh viện hoặc số nhà, tên đường...',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Landmark 81, Chợ Bến Thành, Vincom...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _queryController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
            ),
            onChanged: _handleSearch,
          ),
          const SizedBox(height: 12),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
              ),
            )
          else if (_searchResults.isEmpty && _queryController.text.length >= 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Không tìm thấy địa điểm phù hợp', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      place.streetAddress.isNotEmpty ? place.streetAddress : place.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      place.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectPlace(place);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
