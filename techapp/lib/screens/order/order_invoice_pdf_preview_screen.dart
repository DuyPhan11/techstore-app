import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../config/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/order_invoice_pdf_service.dart';
import '../../utils/toast_helper.dart';

class OrderInvoicePdfPreviewScreen extends StatefulWidget {
  final OrderModel order;

  const OrderInvoicePdfPreviewScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderInvoicePdfPreviewScreen> createState() =>
      _OrderInvoicePdfPreviewScreenState();
}

class _OrderInvoicePdfPreviewScreenState
    extends State<OrderInvoicePdfPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _isExporting = false;

  String get _fileName {
    return 'Hoa_don_${widget.order.orderCode}.pdf';
  }

  Future<Uint8List> _getPdfBytes() async {
    if (_pdfBytes != null) return _pdfBytes!;
    _pdfBytes = await OrderInvoicePdfService.generateInvoicePdf(widget.order);
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
              'Đã lưu hóa đơn PDF thành công:\n${file.path}',
              style: const TextStyle(fontSize: 12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi lưu hóa đơn PDF: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.order.canExportInvoice) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Hóa đơn #${widget.order.orderCode}',
            style: const TextStyle(
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
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    size: 40,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chưa thể xuất hóa đơn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Đơn hàng #${widget.order.orderCode} hiện đang ở trạng thái "${widget.order.statusDisplay}".\n\nHóa đơn điện tử và phiếu xuất kho chỉ được xuất sau khi đơn hàng đã giao thành công (Hoàn thành).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Quay lại đơn hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Hóa đơn #${widget.order.orderCode}',
          style: const TextStyle(
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
            tooltip: 'Chia sẻ hóa đơn',
            onPressed: _isExporting ? null : _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0284C7)),
            tooltip: 'Tải về máy',
            onPressed: _isExporting ? null : () => _fallbackSaveToDisk(),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF475569)),
            tooltip: 'In hóa đơn',
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
                'Đang tạo hóa đơn PDF...',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        onError: (context, error) => _buildFallbackView(context, error),
      ),
    );
  }

  /// View dự phòng khi native rastering chưa khả dụng trước khi restart app
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
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hóa đơn PDF đã sẵn sàng!',
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hóa đơn điện tử hợp lệ của đơn hàng #${widget.order.orderCode}. Bạn có thể tải file về máy, chia sẻ hoặc gửi lệnh in trực tiếp bằng các nút bên dưới.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
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
                      label: const Text('Tải về máy'),
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
                label: const Text('In hóa đơn (Print)'),
                onPressed: _isExporting ? null : _printPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
