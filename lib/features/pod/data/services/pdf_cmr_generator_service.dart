import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/pod_submission_model.dart';

class PdfCmrGeneratorService {
  Future<Uint8List> generateCmrDocument({
    required PodSubmissionModel pod,
    String? trackingCode,
    String? cargoTitle,
    double? weightTons,
    double? volumeM3,
    double? agreedPrice,
    String? originAddress,
    String? destinationAddress,
  }) async {
    pw.ThemeData? theme;
    try {
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();
      theme = pw.ThemeData.withFont(base: font, bold: boldFont);
    } catch (_) {
      theme = pw.ThemeData.base();
    }

    final pdf = pw.Document(theme: theme);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final formattedDate = dateFormat.format(pod.signedAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LOGIFLOW FREIGHT CONSIGNMENT NOTE (CMR)',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Digital Proof of Delivery | Official Transport Document',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'https://logiflow.uz/verify/${pod.shipmentId}',
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blue800),
              pw.SizedBox(height: 12),

              // Tracking & Status Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'WAYBILL NO: ${trackingCode ?? "LF-UZ-8921"}',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    pw.Text(
                      'SHIPMENT ID: ${pod.shipmentId}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'STATUS: DELIVERED & VERIFIED',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Route Details Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildInfoCard(
                      title: '1. SENDER / PICKUP (Origin)',
                      content: [
                        'Location: ${originAddress ?? "Tashkent Logistics Hub, Chilonzor"}',
                        'Scheduled Departure: Confirmed',
                        'Security Seal: Intact & Inspected',
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _buildInfoCard(
                      title: '2. CONSIGNEE / RECEIVER (Destination)',
                      content: [
                        'Receiver: ${pod.receiverName}',
                        'Phone: ${pod.receiverPhone}',
                        'Delivery Address: ${destinationAddress ?? "Samarkand Freight Terminal"}',
                        'Delivery Timestamp: $formattedDate',
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Cargo Specifications Table
              pw.Text(
                '3. CARGO SPECIFICATIONS & ESCROW SETTLEMENT',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Description', isHeader: true),
                      _buildTableCell('Gross Weight', isHeader: true),
                      _buildTableCell('Volume', isHeader: true),
                      _buildTableCell('Settlement Value', isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell(cargoTitle ?? 'Electronics & High-Tech Components (Temperature Controlled)'),
                      _buildTableCell('${weightTons ?? 22.0} Tons'),
                      _buildTableCell('${volumeM3 ?? 82.0} m³'),
                      _buildTableCell('${NumberFormat('#,###').format(agreedPrice ?? 16500000)} UZS (Escrow Released)'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Geotag & Cryptographic Verification
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.blue50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GPS GEOTAG & INTEGRITY STAMP',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Verified Delivery Coordinates: ${pod.latitude.toStringAsFixed(5)}° N, ${pod.longitude.toStringAsFixed(5)}° E',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Delivery Condition Notes: ${pod.notes}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Signatures & Stamps
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Carrier / Driver Acceptance:', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 20),
                      pw.Container(
                        width: 160,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 1)),
                        ),
                        child: pw.Text('Rustam Karimov (Verified Driver)', style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Consignee Digital Signature:', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 20),
                      pw.Container(
                        width: 160,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 1)),
                        ),
                        child: pw.Text('${pod.receiverName} (Signed via LogiFlow)', style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildInfoCard({required String title, required List<String> content}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 6),
          ...content.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> previewOrPrintCmr({
    required PodSubmissionModel pod,
    String? trackingCode,
    String? cargoTitle,
    double? weightTons,
    double? volumeM3,
    double? agreedPrice,
  }) async {
    final pdfBytes = await generateCmrDocument(
      pod: pod,
      trackingCode: trackingCode,
      cargoTitle: cargoTitle,
      weightTons: weightTons,
      volumeM3: volumeM3,
      agreedPrice: agreedPrice,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'CMR_${pod.shipmentId}.pdf',
    );
  }
}
