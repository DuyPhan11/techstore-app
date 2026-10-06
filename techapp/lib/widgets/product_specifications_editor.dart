import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class SpecEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  SpecEntry({String key = '', String value = ''})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class ProductSpecificationsEditorController {
  _ProductSpecificationsEditorState? _state;

  String toJsonString() {
    return _state?.getJsonString() ?? '';
  }

  void loadFromRaw(String? raw) {
    _state?.loadFromRaw(raw);
  }
}

class ProductSpecificationsEditor extends StatefulWidget {
  final String? initialSpecifications;
  final ProductSpecificationsEditorController? controller;
  final VoidCallback? onChanged;

  const ProductSpecificationsEditor({
    super.key,
    this.initialSpecifications,
    this.controller,
    this.onChanged,
  });

  @override
  State<ProductSpecificationsEditor> createState() => _ProductSpecificationsEditorState();
}

class _ProductSpecificationsEditorState extends State<ProductSpecificationsEditor> {
  final List<SpecEntry> _entries = [];

  static const List<String> _defaultKeys = [
    'Màn hình',
    'Vi xử lý (CPU)',
    'RAM',
    'Bộ nhớ trong',
    'Dung lượng pin',
    'Hệ điều hành',
    'Camera',
    'Trọng lượng',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!._state = this;
    }
    loadFromRaw(widget.initialSpecifications);
  }

  @override
  void didUpdateWidget(covariant ProductSpecificationsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      widget.controller!._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void loadFromRaw(String? raw) {
    for (final e in _entries) {
      e.dispose();
    }
    _entries.clear();

    if (raw == null || raw.trim().isEmpty) {
      _loadDefaultFields();
      return;
    }

    final parsedMap = _parseRawSpecs(raw);
    if (parsedMap.isEmpty) {
      _loadDefaultFields();
      return;
    }

    parsedMap.forEach((k, v) {
      final entry = SpecEntry(key: k, value: v);
      _attachListeners(entry);
      _entries.add(entry);
    });

    if (mounted) setState(() {});
  }

  void _loadDefaultFields() {
    for (final k in _defaultKeys) {
      final entry = SpecEntry(key: k, value: '');
      _attachListeners(entry);
      _entries.add(entry);
    }
    if (mounted) setState(() {});
  }

  void _attachListeners(SpecEntry entry) {
    entry.keyController.addListener(_notifyChanged);
    entry.valueController.addListener(_notifyChanged);
  }

  void _notifyChanged() {
    widget.onChanged?.call();
  }

  Map<String, String> _parseRawSpecs(String raw) {
    final Map<String, String> result = {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          final keyStr = k.toString().trim();
          final valStr = v.toString().trim();
          if (keyStr.isNotEmpty) {
            result[keyStr] = valStr;
          }
        });
        return result;
      }
    } catch (_) {
      // Không phải JSON, thử parse từng dòng
    }

    final lines = raw.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        final key = parts[0].replaceAll(RegExp(r'["{}\[\]]'), '').trim();
        final val = parts.sublist(1).join(':').replaceAll(RegExp(r'["{}\[\]]'), '').trim();
        if (key.isNotEmpty) {
          result[key] = val;
        }
      }
    }

    return result;
  }

  String getJsonString() {
    final Map<String, String> map = {};
    for (final e in _entries) {
      final k = e.keyController.text.trim();
      final v = e.valueController.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        map[k] = v;
      }
    }
    if (map.isEmpty) return '';
    return jsonEncode(map);
  }

  void _addNewField([String key = '', String value = '']) {
    final entry = SpecEntry(key: key, value: value);
    _attachListeners(entry);
    setState(() {
      _entries.add(entry);
    });
    _notifyChanged();
  }

  void _removeField(int index) {
    setState(() {
      final removed = _entries.removeAt(index);
      removed.dispose();
    });
    _notifyChanged();
  }

  void _resetToDefault() {
    for (final e in _entries) {
      e.dispose();
    }
    _entries.clear();
    _loadDefaultFields();
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Danh sách thông số kỹ thuật:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 15, color: AppColors.primary),
              label: const Text('Đặt lại mẫu', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _resetToDefault,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'Chưa có thông số nào. Nhấn "+ Thêm thông số" bên dưới để tạo.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tên thông số (Key)
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: entry.keyController,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Tên thông số (RAM, CPU...)',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Giá trị thông số (Value)
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: entry.valueController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Giá trị (16GB, 120Hz...)',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Nút xóa trường này
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                      tooltip: 'Xóa thông số này',
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => _removeField(index),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 10),

        // Nút thêm thông số mới
        OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Thêm thông số mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () => _addNewField(),
        ),
      ],
    );
  }
}
