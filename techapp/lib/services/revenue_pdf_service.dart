import 'dart:typed_data';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/admin_dashboard_model.dart';

class RevenuePdfService {
  /// Định dạng tiền tệ an toàn cho PDF (tránh ký hiệu ₫ U+20AB bị lỗi font trên một số thiết bị)
  static String _formatCurrency(num amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  /// Tạo file PDF báo cáo doanh thu trả về Uint8List bytes
  static Future<Uint8List> generateRevenuePdf({
    required DashboardSummaryModel summary,
    DateTimeRange? dateRange,
    int? selectedDays,
  }) async {
    final pdf = pw.Document();

    // 1. Nạp font hỗ trợ đầy đủ tiếng Việt UTF-8 (Ưu tiên font local tải trong assets, sau đó mới tải từ Google Fonts)
    pw.Font fontRegular;
    pw.Font fontBold;

    try {
      final fontData = await rootBundle.load('assets/google_fonts/Roboto-Regular.ttf');
      fontRegular = pw.Font.ttf(fontData);
    } catch (_) {
      try {
        fontRegular = await PdfGoogleFonts.robotoRegular();
      } catch (_) {
        fontRegular = pw.Font.helvetica();
      }
    }

    try {
      final fontBoldData = await rootBundle.load('assets/google_fonts/Roboto-Bold.ttf');
      fontBold = pw.Font.ttf(fontBoldData);
    } catch (_) {
      try {
        fontBold = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        fontBold = pw.Font.helveticaBold();
      }
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final dfDisplay = DateFormat('dd/MM/yyyy');
    final dfDateTime = DateFormat('dd/MM/yyyy HH:mm:ss');
    final now = DateTime.now();

    // Xác định thời gian báo cáo
    String periodText;
    if (dateRange != null) {
      periodText =
          'Từ ngày ${dfDisplay.format(dateRange.start)} đến ngày ${dfDisplay.format(dateRange.end)}';
    } else if (summary.startDate != null && summary.endDate != null) {
      periodText = 'Từ ngày ${summary.startDate} đến ngày ${summary.endDate}';
    } else {
      periodText = '${selectedDays ?? 30} ngày gần nhất (tính đến ${dfDisplay.format(now)})';
    }

    final double avgOrderValue = summary.completedOrders > 0
        ? summary.totalRevenue / summary.completedOrders
        : 0.0;
    final double completionRate = summary.totalOrders > 0
        ? (summary.completedOrders / summary.totalOrders) * 100.0
        : 0.0;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(context, periodText, dfDateTime.format(now)),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),

          // 1. Khối KPI chỉ số kinh doanh chính
          _buildKpiSection(summary, avgOrderValue, completionRate),
          pw.SizedBox(height: 16),

          // 2. Bảng cơ cấu doanh thu theo danh mục
          _buildCategorySection(summary),
          pw.SizedBox(height: 16),

          // 3. Bảng Top sản phẩm bán chạy nhất
          if (summary.bestSellingProducts.isNotEmpty) ...[
            _buildBestSellingSection(summary),
            pw.SizedBox(height: 16),
          ],

          // 4. Bảng doanh thu theo thời gian (nếu có)
          if (summary.revenueOverTime.isNotEmpty) ...[
            _buildTimelineSection(summary),
            pw.SizedBox(height: 20),
          ],

          // 5. Phần chữ ký và xác nhận
          _buildSignatureSection(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Header trang báo cáo
  static pw.Widget _buildHeader(
    pw.Context context,
    String periodText,
    String printedAt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TECHSTORE VIỆT NAM',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Hệ thống bán lẻ thiết bị công nghệ & phụ kiện cao cấp',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Hotline: 1900 6868 | Email: contact@techstore.vn | Website: techstore.vn',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.indigo200),
              ),
              child: pw.Text(
                'BÁO CÁO NỘI BỘ',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.8, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'BÁO CÁO KẾT QUẢ KINH DOANH & DOANH THU',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Kỳ báo cáo: $periodText',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Thời điểm xuất: $printedAt | Đơn vị tiền tệ: VNĐ',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Footer trang
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.8, color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Trích xuất tự động từ hệ thống TechStore Management System',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.Text(
              'Trang ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Phần chỉ số tổng quan
  static pw.Widget _buildKpiSection(
    DashboardSummaryModel summary,
    double avgOrderValue,
    double completionRate,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'I. CHỈ SỐ KINH DOANH TỔNG QUAN',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildMetricCard(
                title: 'TỔNG DOANH THU',
                value: _formatCurrency(summary.totalRevenue),
                color: PdfColors.indigo700,
                isPrimary: true,
              ),
              pw.SizedBox(width: 8),
              _buildMetricCard(
                title: 'TỔNG ĐƠN HÀNG',
                value: '${summary.totalOrders} đơn',
                subtitle:
                    'Thành công: ${summary.completedOrders} | Hủy: ${summary.cancelledOrders}',
                color: PdfColors.blueGrey800,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _buildMetricCard(
                title: 'TỶ LỆ THÀNH CÔNG',
                value: '${completionRate.toStringAsFixed(1)}%',
                subtitle: 'Đơn giao hoàn tất / Tổng đơn',
                color: PdfColors.green700,
              ),
              pw.SizedBox(width: 8),
              _buildMetricCard(
                title: 'GIÁ TRỊ ĐƠN TB (AOV)',
                value: _formatCurrency(avgOrderValue),
                subtitle: 'Doanh thu / Đơn hoàn tất',
                color: PdfColors.teal700,
              ),
              pw.SizedBox(width: 8),
              _buildMetricCard(
                title: 'KHÁCH HÀNG',
                value: '+${summary.newCustomers} mới',
                subtitle: 'Tổng cộng: ${summary.totalCustomers} KH',
                color: PdfColors.purple700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required PdfColor color,
    bool isPrimary = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(
          color: isPrimary ? PdfColors.indigo50 : PdfColors.white,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(
            color: isPrimary ? PdfColors.indigo300 : PdfColors.grey300,
            width: isPrimary ? 1.0 : 0.6,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: isPrimary ? PdfColors.indigo900 : PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isPrimary ? 12 : 10.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              pw.SizedBox(height: 1),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Phần cơ cấu danh mục
  static pw.Widget _buildCategorySection(DashboardSummaryModel summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'II. TỶ TRỌNG DOANH THU THEO DANH MỤC',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              children: [
                _tableHeaderCell('STT', align: pw.TextAlign.center),
                _tableHeaderCell('Tên Danh mục'),
                _tableHeaderCell('Doanh thu (VNĐ)', align: pw.TextAlign.right),
                _tableHeaderCell('Tỷ trọng (%)', align: pw.TextAlign.right),
              ],
            ),
            // Rows
            ...summary.revenueByCategory.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final bg = idx % 2 == 0 ? PdfColors.white : PdfColors.grey100;

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  _tableCell('${idx + 1}', align: pw.TextAlign.center),
                  _tableCell(cat.categoryName, isBold: true),
                  _tableCell(_formatCurrency(cat.revenue),
                      align: pw.TextAlign.right),
                  _tableCell('${cat.percentage.toStringAsFixed(1)}%',
                      align: pw.TextAlign.right, isBold: true),
                ],
              );
            }),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
              children: [
                _tableCell('', align: pw.TextAlign.center),
                _tableCell('TỔNG CỘNG', isBold: true),
                _tableCell(
                  _formatCurrency(summary.totalRevenue),
                  align: pw.TextAlign.right,
                  isBold: true,
                ),
                _tableCell('100.0%', align: pw.TextAlign.right, isBold: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Phần Top sản phẩm bán chạy
  static pw.Widget _buildBestSellingSection(DashboardSummaryModel summary) {
    final list = summary.bestSellingProducts;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'III. TOP SẢN PHẨM BÁN CHẠY NHẤT',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(3.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              children: [
                _tableHeaderCell('Top', align: pw.TextAlign.center),
                _tableHeaderCell('Tên sản phẩm'),
                _tableHeaderCell('Mã SKU'),
                _tableHeaderCell('Đã bán', align: pw.TextAlign.center),
                _tableHeaderCell('Doanh thu (VNĐ)', align: pw.TextAlign.right),
              ],
            ),
            // Rows
            ...list.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              final bg = idx % 2 == 0 ? PdfColors.white : PdfColors.grey100;

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  _tableCell('#${idx + 1}',
                      align: pw.TextAlign.center, isBold: true),
                  _tableCell(p.productName),
                  _tableCell(p.productSku ?? '-'),
                  _tableCell('${p.quantitySold}', align: pw.TextAlign.center),
                  _tableCell(_formatCurrency(p.totalRevenue),
                      align: pw.TextAlign.right, isBold: true),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Phần chi tiết theo ngày
  static pw.Widget _buildTimelineSection(DashboardSummaryModel summary) {
    final timeline = summary.revenueOverTime;
    final displayList = timeline.length > 15 ? timeline.sublist(timeline.length - 15) : timeline;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'IV. CHI TIẾT DOANH THU THEO NGÀY',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            if (timeline.length > 15)
              pw.Text(
                '(Hiển thị 15 ngày gần nhất)',
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey600,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              children: [
                _tableHeaderCell('STT', align: pw.TextAlign.center),
                _tableHeaderCell('Ngày', align: pw.TextAlign.center),
                _tableHeaderCell('Số đơn', align: pw.TextAlign.center),
                _tableHeaderCell('Doanh thu ngày (VNĐ)', align: pw.TextAlign.right),
              ],
            ),
            ...displayList.asMap().entries.map((entry) {
              final idx = entry.key;
              final pt = entry.value;
              final bg = idx % 2 == 0 ? PdfColors.white : PdfColors.grey100;

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  _tableCell('${idx + 1}', align: pw.TextAlign.center),
                  _tableCell(_formatDate(pt.date), align: pw.TextAlign.center),
                  _tableCell('${pt.orderCount} đơn', align: pw.TextAlign.center),
                  _tableCell(_formatCurrency(pt.revenue),
                      align: pw.TextAlign.right,
                      isBold: pt.revenue > 0),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Phần chữ ký và xác nhận
  static pw.Widget _buildSignatureSection() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 14),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSignatureBlock('NGƯỜI LẬP BIỂU', '(Ký và ghi rõ họ tên)'),
            _buildSignatureBlock('KẾ TOÁN TRƯỞNG', '(Ký và ghi rõ họ tên)'),
            _buildSignatureBlock('GIÁM ĐỐC / ĐẠI DIỆN', '(Ký, đóng dấu)'),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildSignatureBlock(String title, String subtitle) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 35),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  static String _formatDate(String yyyyMmDd) {
    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return yyyyMmDd;
  }
}
