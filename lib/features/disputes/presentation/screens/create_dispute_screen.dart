import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/dispute_model.dart';
import '../bloc/dispute_bloc.dart';
import '../bloc/dispute_event.dart';

class CreateDisputeScreen extends StatefulWidget {
  final String? initialShipmentId;
  final String? initialTrackingCode;

  const CreateDisputeScreen({
    super.key,
    this.initialShipmentId,
    this.initialTrackingCode,
  });

  @override
  State<CreateDisputeScreen> createState() => _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  late TextEditingController _trackingController;
  final _descController = TextEditingController();
  final _amountController = TextEditingController(text: '2,500,000');
  DisputeReason _selectedReason = DisputeReason.damagedCargo;
  final List<String> _attachedPhotos = ['damaged_cargo_dock_1.jpg'];

  @override
  void initState() {
    super.initState();
    _trackingController = TextEditingController(text: widget.initialTrackingCode ?? 'LF-UZ-8492');
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    final user = context.read<AuthBloc>().state.user;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 1000000.0;

    context.read<DisputeBloc>().add(
          CreateDisputeSubmitted(
            shipmentId: widget.initialShipmentId ?? 'SHP-1001',
            trackingCode: _trackingController.text.trim(),
            claimantName: user?.companyName ?? user?.fullName ?? 'Claimant',
            reason: _selectedReason,
            description: _descController.text.trim(),
            claimAmount: amount,
            evidencePhotos: _attachedPhotos,
          ),
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('disputes.openDispute'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tracking code input
            AppTextField(
              controller: _trackingController,
              label: 'Load Tracking Code',
              hint: 'LF-UZ-0000',
              prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
            ),
            const SizedBox(height: 16),

            // Reason selector
            Text(
              'disputes.reason'.tr(),
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
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DisputeReason>(
                  value: _selectedReason,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  items: DisputeReason.values.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Icon(r.icon, size: 18, color: AppColors.rose),
                          const SizedBox(width: 10),
                          Text(r.labelKey.tr(), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Claim Amount
            AppTextField(
              controller: _amountController,
              label: 'disputes.claimAmount'.tr(),
              hint: '2,500,000',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
            ),
            const SizedBox(height: 16),

            // Description
            AppTextField(
              controller: _descController,
              label: 'disputes.description'.tr(),
              hint: 'Provide details about damaged items, time delays or missing paperwork...',
              maxLines: 4,
              prefixIcon: const Icon(Icons.notes_rounded, size: 20),
            ),
            const SizedBox(height: 18),

            // Evidence Photos Attachment simulator
            Text(
              'disputes.attachEvidence'.tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _attachedPhotos.add('damage_photo_${_attachedPhotos.length + 1}.jpg');
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.rose.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: AppColors.rose),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_attachedPhotos.length} photos / waybill scans attached',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              text: 'disputes.openDispute'.tr(),
              prefixIcon: Icons.gavel_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
