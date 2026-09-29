import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../shipments/presentation/bloc/shipment_event.dart';
import '../../data/services/media_picker_service.dart';
import '../../data/services/pdf_cmr_generator_service.dart';
import '../../domain/models/pod_submission_model.dart';
import '../bloc/pod_bloc.dart';
import '../bloc/pod_event.dart';
import '../bloc/pod_state.dart';
import '../widgets/signature_pad_canvas.dart';
import '../widgets/return_trip_dialog.dart';

class PodScreen extends StatefulWidget {
  final String shipmentId;

  const PodScreen({super.key, required this.shipmentId});

  @override
  State<PodScreen> createState() => _PodScreenState();
}

class _PodScreenState extends State<PodScreen> {
  final TextEditingController _receiverNameController = TextEditingController(text: 'Shoxrux Abdullayev');
  final TextEditingController _receiverPhoneController = TextEditingController(text: '+998 90 987 65 43');
  final TextEditingController _notesController = TextEditingController(text: 'Cargo delivered intact with undamaged security seals.');

  final MediaPickerService _mediaPicker = MediaPickerService();
  final PdfCmrGeneratorService _pdfGenerator = PdfCmrGeneratorService();

  final List<XFile> _capturedPhotos = [];
  List<List<Offset>> _signatureStrokes = [];
  bool _cargoConditionChecked = true;
  bool _quantityVerified = true;
  bool _temperatureCompliant = true;
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleTakePhoto() async {
    final photo = await _mediaPicker.takePhoto();
    if (photo != null && mounted) {
      setState(() => _capturedPhotos.add(photo));
    }
  }

  Future<void> _handleGeneratePdf() async {
    setState(() => _isGeneratingPdf = true);

    final submission = _buildPodSubmission();
    await _pdfGenerator.previewOrPrintCmr(
      pod: submission,
      trackingCode: 'LF-UZ-8921',
      cargoTitle: 'Industrial Electronics & High-Tech Components',
      weightTons: 22.0,
      volumeM3: 82.0,
      agreedPrice: 16500000.0,
    );

    if (mounted) {
      setState(() => _isGeneratingPdf = false);
    }
  }

  PodSubmissionModel _buildPodSubmission() {
    return PodSubmissionModel(
      shipmentId: widget.shipmentId,
      receiverName: _receiverNameController.text,
      receiverPhone: _receiverPhoneController.text,
      notes: _notesController.text,
      signedAt: DateTime.now(),
      latitude: 39.6542,
      longitude: 66.9597,
      cargoPhotos: _capturedPhotos.isNotEmpty
          ? _capturedPhotos.map((f) => f.name).toList()
          : const ['seal_photo_1.jpg', 'dock_delivery_2.jpg'],
      signatureStrokes: _signatureStrokes,
      isApproved: true,
    );
  }

  void _handleSubmit() {
    final submission = _buildPodSubmission();

    context.read<PodBloc>().add(SubmitPodRequested(submission));

    final role = context.read<AuthBloc>().state.user?.role ?? UserRole.driver;
    context.read<ShipmentBloc>().add(
          AdvanceShipmentStatusSubmitted(
            shipmentId: widget.shipmentId,
            nextStatus: LoadStatus.delivered,
            currentRole: role,
          ),
        );

    // Prompt Return Trip Dialog for drivers
    if (role == UserRole.driver || role == UserRole.carrier) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ReturnTripDialog(
          destinationCity: 'Samarkand',
          originCity: 'Tashkent',
        ),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<PodBloc, PodState>(
      listener: (context, state) {
        if (state.status == PodStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('common.success'.tr()),
              backgroundColor: AppColors.emerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == PodStatus.loading;

        return Scaffold(
          appBar: AppBar(
            title: Text('pod.title'.tr()),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Preview & Print CMR PDF',
                onPressed: _isGeneratingPdf ? null : _handleGeneratePdf,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Geotag Stamp Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.emerald, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'pod.geotagStamp'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GPS: 39.6542° N, 66.9597° E • ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Consignee Contact Details
                _SectionTitle(title: 'pod.consigneeDetails'.tr()),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'pod.receiverName'.tr(),
                  controller: _receiverNameController,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'pod.receiverPhone'.tr(),
                  controller: _receiverPhoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
                const SizedBox(height: 20),

                // Cargo Proof Photos with Native Camera
                const _SectionTitle(title: 'Cargo & Seal Proof Photos (Kamera)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: _handleTakePhoto,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 24),
                            SizedBox(height: 4),
                            Text('Take Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _capturedPhotos.isEmpty
                          ? Text(
                              'Tap to take photo of intact security seals or cargo handover.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            )
                          : SizedBox(
                              height: 76,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _capturedPhotos.length,
                                itemBuilder: (ctx, i) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(8),
                                    width: 76,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle, color: AppColors.emerald, size: 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Seal #${i + 1}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Inspection Checklist
                _SectionTitle(title: 'pod.inspectionChecklist'.tr()),
                const SizedBox(height: 10),
                _CheckboxTile(
                  title: 'pod.sealIntact'.tr(),
                  value: _cargoConditionChecked,
                  onChanged: (v) => setState(() => _cargoConditionChecked = v ?? false),
                ),
                _CheckboxTile(
                  title: 'pod.quantityVerified'.tr(),
                  value: _quantityVerified,
                  onChanged: (v) => setState(() => _quantityVerified = v ?? false),
                ),
                _CheckboxTile(
                  title: 'pod.tempCompliant'.tr(),
                  value: _temperatureCompliant,
                  onChanged: (v) => setState(() => _temperatureCompliant = v ?? false),
                ),
                const SizedBox(height: 20),

                // Digital Signature Pad Canvas
                _SectionTitle(title: 'pod.digitalSignature'.tr()),
                const SizedBox(height: 10),
                SignaturePadCanvas(
                  onSignatureChanged: (strokes) {
                    setState(() => _signatureStrokes = strokes);
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                AppTextField(
                  label: 'pod.notes'.tr(),
                  controller: _notesController,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                ),
                const SizedBox(height: 24),

                // Action Buttons: Generate PDF CMR & Sign/Release
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Preview CMR PDF',
                        variant: AppButtonVariant.outline,
                        prefixIcon: Icons.print_rounded,
                        isLoading: _isGeneratingPdf,
                        onPressed: _handleGeneratePdf,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: 'pod.signAndRelease'.tr(),
                        isLoading: isLoading,
                        prefixIcon: Icons.fingerprint_rounded,
                        onPressed: _handleSubmit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.emerald,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
