import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/document_model.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';

class UploadDocumentModal extends StatefulWidget {
  final UserRole userRole;

  const UploadDocumentModal({super.key, required this.userRole});

  static Future<void> show(BuildContext context, UserRole role) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentBloc>(),
        child: UploadDocumentModal(userRole: role),
      ),
    );
  }

  @override
  State<UploadDocumentModal> createState() => _UploadDocumentModalState();
}

class _UploadDocumentModalState extends State<UploadDocumentModal> {
  late LogisticsDocType _selectedType;
  final _numberController = TextEditingController();
  DateTime _issueDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  String? _selectedFileName = 'document_scan_2026.pdf';

  @override
  void initState() {
    super.initState();
    final availableTypes = LogisticsDocType.values.where((t) {
      if (widget.userRole == UserRole.driver) return t == LogisticsDocType.driverLicense;
      if (widget.userRole == UserRole.carrier) return t == LogisticsDocType.vehicleReg || t == LogisticsDocType.cmrInsurance;
      return t == LogisticsDocType.companyReg || t == LogisticsDocType.cargoClearance;
    }).toList();
    _selectedType = availableTypes.isNotEmpty ? availableTypes.first : LogisticsDocType.driverLicense;
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isExpiry) async {
    final initialDate = isExpiry ? _expiryDate : _issueDate;
    final firstDate = isExpiry ? DateTime.now() : DateTime(2015);
    final lastDate = DateTime(2035);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_numberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    context.read<DocumentBloc>().add(
          UploadDocumentSubmitted(
            docType: _selectedType,
            docNumber: _numberController.text.trim(),
            issueDate: _issueDate,
            expiryDate: _expiryDate,
            fileName: _selectedFileName ?? 'document.pdf',
            userRole: widget.userRole,
          ),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('documents.uploadSuccess'.tr()),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('yyyy-MM-dd');

    final typesForRole = LogisticsDocType.values.where((t) {
      if (widget.userRole == UserRole.driver) return t == LogisticsDocType.driverLicense;
      if (widget.userRole == UserRole.carrier) return t == LogisticsDocType.vehicleReg || t == LogisticsDocType.cmrInsurance;
      return t == LogisticsDocType.companyReg || t == LogisticsDocType.cargoClearance;
    }).toList();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'documents.uploadDoc'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Document type selector
            Text(
              'documents.selectType'.tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<LogisticsDocType>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  items: typesForRole.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(t.labelKey.tr(), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Document Number
            AppTextField(
              controller: _numberController,
              label: 'documents.docNumber'.tr(),
              hint: 'AA 1234567 / STIR 309...',
              prefixIcon: const Icon(Icons.pin_outlined, size: 20),
            ),
            const SizedBox(height: 16),

            // Dates Pickers (Issue & Expiry)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issue Date',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(_issueDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'documents.expiresOn'.tr(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(_expiryDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.emerald),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // File selection simulator
            InkWell(
              onTap: () {
                setState(() {
                  _selectedFileName = 'doc_scanned_${DateTime.now().millisecondsSinceEpoch % 1000}.pdf';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFileName ?? 'documents.selectFile'.tr(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PDF / JPG / PNG (Max 15MB)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              text: 'common.submit'.tr(),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
