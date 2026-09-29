import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/features/pod/data/services/pdf_cmr_generator_service.dart';
import 'package:logiflow_mobile/features/pod/domain/models/pod_submission_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF CMR Consignment Note Tests', () {
    test('PdfCmrGeneratorService produces non-empty PDF binary bytes', () async {
      final service = PdfCmrGeneratorService();
      final pod = PodSubmissionModel(
        shipmentId: 'SHP-1001',
        receiverName: 'Shoxrux Abdullayev',
        receiverPhone: '+998 90 987 65 43',
        notes: 'Cargo intact and verified.',
        signedAt: DateTime.now(),
        latitude: 39.6542,
        longitude: 66.9597,
        cargoPhotos: const ['seal_photo_1.jpg'],
        signatureStrokes: const [],
        isApproved: true,
      );

      final pdfBytes = await service.generateCmrDocument(
        pod: pod,
        trackingCode: 'LF-UZ-8921',
        cargoTitle: 'Industrial Electronics',
        weightTons: 22.0,
        volumeM3: 82.0,
        agreedPrice: 16500000.0,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF documents start with '%PDF-'
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });
}
