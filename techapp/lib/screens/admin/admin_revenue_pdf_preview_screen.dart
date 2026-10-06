import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../config/app_colors.dart';
import '../../models/admin_dashboard_model.dart';
import '../../services/revenue_pdf_service.dart';
import '../../utils/toast_helper.dart';

class AdminRevenuePdfPreviewScreen extends StatefulWidget {
  final DashboardSummaryModel summary;
  final DateTimeRange? dateRange;
  final int? selectedDays;

  const AdminRevenuePdfPreviewScreen({
    super.key,
    required this.summary,
    this.dateRange,
    this.selectedDays,
  });

  @override
  State<AdminRevenuePdfPreviewScreen> createState() =>
      _AdminRevenuePdfPreviewScreenState();
}

class _AdminRevenuePdfPreviewScreenState
    extends State<AdminRevenuePdfPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _isExporting = false;

  String get _fileName {
    final now = DateTime.now();
    return 'Bao_cao_doanh_thu_TechStore_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
  }

  Future<Uint8List> _getPdfBytes() async {
    if (_pdfBytes != null) return _pdfBytes!;
    _pdfBytes = await RevenuePdfService.generateRevenuePdf(
      summary: widget.summary,
      dateRange: widget.dateRange,
      selectedDays: widget.selectedDays,
    );
    return _pdfBytes!;
  }

  Future<void> _sharePdf() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _getPdfBytes();
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
    } catch (e) {
      if (mounted) {
        _fallbackSaveToDisk(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _printPdf() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _getPdfBytes();
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: _fileName,
      );
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi kết nối máy in: $e');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _fallbackSaveToDisk([String? reason]) async {
    try {
      final bytes = await _getPdfBytes();
      Directory? dir;

      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          dir = downloadDir;
        }
      }

      dir ??= await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Đã lưu file PDF thành công:\n${file.path}',
              style: const TextStyle(fontSize: 12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi lưu file PDF: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Xuất báo cáo doanh thu PDF',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Chia sẻ PDF',
            onPressed: _isExporting ? null : _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0284C7)),
            tooltip: 'Lưu file PDF',
            onPressed: _isExporting ? null : () => _fallbackSaveToDisk(),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF475569)),
            tooltip: 'In tài liệu',
            onPressed: _isExporting ? null : _printPdf,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _getPdfBytes(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: _fileName,
        previewPageMargin: const EdgeInsets.all(12),
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Đang tạo tài liệu PDF...',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        onError: (context, error) => _buildFallbackView(context, error),
      ),
    );
  }

  /// View thay thế thân thiện khi native rastering chưa khả dụng (trước khi rebuild app)
  Widget _buildFallbackView(BuildContext context, Object error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 36,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Báo cáo PDF đã sẵn sàng!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _fileName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tính năng xem trước trang trực tiếp yêu cầu khởi động lại ứng dụng một lần (chạy lại flutter run) để nạp đầy đủ plugin in ấn. Tuy nhiên bạn có thể lưu hoặc chia sẻ file PDF ngay bên dưới!',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF78350F),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Direct Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Chia sẻ PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isExporting ? null : _sharePdf,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Lưu vào máy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        foregroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isExporting ? null : () => _fallbackSaveToDisk(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('In tài liệu (Print)'),
                onPressed: _isExporting ? null : _printPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
