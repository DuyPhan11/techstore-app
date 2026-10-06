import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

class OrderInvoicePdfService {
  /// Định dạng tiền tệ an toàn cho PDF UTF-8
  static String _formatCurrency(num amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  /// Tạo tài liệu PDF Hóa đơn đơn hàng
  static Future<Uint8List> generateInvoicePdf(OrderModel order) async {
    if (!order.canExportInvoice) {
      throw Exception('Chỉ có thể xuất hóa đơn cho đơn hàng đã hoàn tất (giao thành công)');
    }

    final pdf = pw.Document();

    // 1. Nạp font hỗ trợ đầy đủ tiếng Việt UTF-8
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

    final dfDateTime = DateFormat('dd/MM/yyyy HH:mm:ss');
    final dfDisplay = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();

    DateTime? orderDate;
    if (order.createdAt != null) {
      try {
        orderDate = DateTime.parse(order.createdAt!);
      } catch (_) {}
    }
    final orderDateStr = orderDate != null ? dfDateTime.format(orderDate) : dfDisplay.format(now);

    final vatPercent = (order.vatRate * 100).toStringAsFixed(0);
    final calculatedVat = order.taxAmount > 0
        ? order.taxAmount
        : ((order.totalItemsAmount - order.discountAmount) * order.vatRate).roundToDouble();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (context) => _buildHeader(order, orderDateStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),

          // 1. Thông tin khách hàng & Giao nhận
          _buildCustomerInfo(order),
          pw.SizedBox(height: 14),

          // 2. Bảng chi tiết sản phẩm trong đơn hàng
          _buildItemsTable(order),
          pw.SizedBox(height: 12),

          // 3. Khối thanh toán & Công thức tính tổng tiền
          _buildPaymentSummary(order, vatPercent, calculatedVat),
          pw.SizedBox(height: 16),

          // 4. Chính sách bảo hành & Lời cảm ơn
          _buildPolicyAndNote(),
          pw.SizedBox(height: 24),

          // 5. Khối chữ ký xác nhận
          _buildSignatures(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Tiêu đề hóa đơn & Thông tin công ty
  static pw.Widget _buildHeader(OrderModel order, String orderDateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Thông tin thương hiệu TechStore
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TECHSTORE VIỆT NAM',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Hệ thống bán lẻ thiết bị công nghệ chính hãng',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Hotline: 1900 8888  •  Email: hotro@techstore.vn  •  Website: techstore.vn',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'MST: 0108999888  •  Địa chỉ: 123 Cầu Giấy, Quan Hoa, Cầu Giấy, Hà Nội',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                ),
              ],
            ),
            // Mã hóa đơn & Trạng thái
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.orange200),
                  ),
                  child: pw.Text(
                    'HÓA ĐƠN BÁN HÀNG',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Mã đơn: #${order.orderCode}',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
                pw.Text(
                  'Ngày lập: $orderDateStr',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1.5, color: PdfColors.orange800),
      ],
    );
  }

  /// Khối thông tin khách hàng & Giao nhận
  static pw.Widget _buildCustomerInfo(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Cột 1: Thông tin người nhận
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'THÔNG TIN NGƯỜI NHẬN:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.SizedBox(height: 4),
                _buildInfoLine('Họ và tên:', order.recipientName),
                _buildInfoLine('Điện thoại:', order.recipientPhone),
                _buildInfoLine('Địa chỉ:', order.shippingAddress),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _buildInfoLine('Ghi chú:', order.notes!),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          // Cột 2: Thông tin giao dịch & Chi nhánh
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'THÔNG TIN ĐƠN HÀNG:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.SizedBox(height: 4),
                _buildInfoLine('Chi nhánh xuất:', order.branchName ?? 'Kho tổng TechStore'),
                _buildInfoLine('Trạng thái đơn:', order.statusDisplay),
                _buildInfoLine('Phương thức:', order.paymentMethodDisplay),
                _buildInfoLine(
                  'Thanh toán:',
                  order.paymentStatus == 'PAID' ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN (COD)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 75,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  /// Bảng sản phẩm trong đơn
  static pw.Widget _buildItemsTable(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DANH SÁCH SẢN PHẨM / ORDER ITEMS',
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),   // STT
            1: pw.FlexColumnWidth(6),   // Tên sản phẩm
            2: pw.FlexColumnWidth(2.5), // Đơn giá
            3: pw.FlexColumnWidth(1.2), // Số lượng
            4: pw.FlexColumnWidth(2.8), // Thành tiền
          },
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeaderCell('STT'),
                _buildTableHeaderCell('Tên sản phẩm & SKU', align: pw.TextAlign.left),
                _buildTableHeaderCell('Đơn giá', align: pw.TextAlign.right),
                _buildTableHeaderCell('SL'),
                _buildTableHeaderCell('Thành tiền', align: pw.TextAlign.right),
              ],
            ),
            // Table Rows
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              final isEven = entry.key % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                children: [
                  _buildTableCell('$index', align: pw.TextAlign.center),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.productName,
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Row(
                          children: [
                            if (item.productSku != null && item.productSku!.isNotEmpty)
                              pw.Text(
                                'SKU: ${item.productSku}  |  ',
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                              ),
                            pw.Text(
                              'Bảo hành: ${item.warrantyMonths} tháng chính hãng',
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildTableCell(_formatCurrency(item.unitPrice), align: pw.TextAlign.right),
                  _buildTableCell('${item.quantity}', align: pw.TextAlign.center),
                  _buildTableCell(_formatCurrency(item.subtotal), align: pw.TextAlign.right, isBold: true),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  /// Khối chi tiết thanh toán theo công thức minh bạch
  static pw.Widget _buildPaymentSummary(
    OrderModel order,
    String vatPercent,
    double calculatedVat,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Khung ghi chú công thức minh bạch
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CƠ CHẾ TÍNH TIỀN MINH BẠCH:',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '• Tổng thanh toán = Tiền hàng - Giảm giá + Phí vận chuyển + Thuế VAT',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '• Phí vận chuyển: Miễn phí cho đơn từ 5.000.000 đ hoặc nhận tại cửa hàng; 30.000 đ đối với giao hàng tiêu chuẩn.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '• Thuế VAT ($vatPercent%): Thuế giá trị gia tăng áp dụng cho thiết bị điện tử theo quy định.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        // Bảng tổng hợp số tiền
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow('Tạm tính (Tiền hàng):', _formatCurrency(order.totalItemsAmount)),
                if (order.discountAmount > 0)
                  _buildSummaryRow(
                    'Giảm giá voucher (${order.couponCode ?? ""}):',
                    '-${_formatCurrency(order.discountAmount)}',
                    color: PdfColors.green800,
                  ),
                _buildSummaryRow(
                  'Phí vận chuyển:',
                  order.shippingFee > 0 ? '+${_formatCurrency(order.shippingFee)}' : '0 đ (Miễn phí)',
                  color: order.shippingFee == 0 ? PdfColors.green800 : null,
                ),
                _buildSummaryRow(
                  'Thuế VAT ($vatPercent%):',
                  '+${_formatCurrency(calculatedVat)}',
                ),
                pw.Divider(thickness: 0.8, color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TỔNG THANH TOÁN:',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                    ),
                    pw.Text(
                      _formatCurrency(order.finalAmount),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  /// Chính sách & Lời cảm ơn
  static pw.Widget _buildPolicyAndNote() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CHÍNH SÁCH BẢO HÀNH & ĐỔI TRẢ:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '1. Cam kết 100% sản phẩm chính hãng, bảo hành theo thời hạn từng linh kiện/thiết bị tại TTBH ủy quyền của hãng trên toàn quốc.\n'
            '2. Hỗ trợ 1 đổi 1 hoặc hoàn tiền trực tuyến qua ứng dụng TechStore trong vòng 7 ngày đầu nếu có lỗi phần cứng từ NSX.\n'
            '3. Quý khách vui lòng xuất trình hóa đơn điện tử này khi yêu cầu bảo hành hoặc khiếu nại sản phẩm. Cảm ơn Quý khách!',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, height: 1.3),
          ),
        ],
      ),
    );
  }

  /// Khối chữ ký xác nhận
  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text('NGƯỜI MUA HÀNG', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text('(Ký và ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
              pw.SizedBox(height: 38),
              pw.Text('........................................', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text('NGƯỜI GIAO HÀNG', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text('(Ký và ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
              pw.SizedBox(height: 38),
              pw.Text('........................................', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text('ĐẠI DIỆN TECHSTORE', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
              pw.Text('(Thủ kho / Người lập hóa đơn)', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
              pw.SizedBox(height: 38),
              pw.Text('(Đã ký điện tử & đóng dấu)', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.green800)),
            ],
          ),
        ),
      ],
    );
  }

  /// Chân trang mỗi trang PDF
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TechStore Việt Nam  •  Hóa đơn điện tử hợp lệ theo Nghị định 123/2020/NĐ-CP',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
          ),
          pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
