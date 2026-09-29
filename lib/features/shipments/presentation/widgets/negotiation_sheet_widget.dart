import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/shipment_model.dart';
import '../bloc/shipment_bloc.dart';
import '../bloc/shipment_event.dart';

class NegotiationSheetWidget extends StatefulWidget {
  final ShipmentModel shipment;

  const NegotiationSheetWidget({super.key, required this.shipment});

  static Future<void> show(BuildContext context, ShipmentModel shipment) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ShipmentBloc>(),
        child: NegotiationSheetWidget(shipment: shipment),
      ),
    );
  }

  @override
  State<NegotiationSheetWidget> createState() => _NegotiationSheetWidgetState();
}

class _NegotiationSheetWidgetState extends State<NegotiationSheetWidget> {
  final _counterController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isCounterMode = false;

  @override
  void dispose() {
    _counterController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###', 'en_US');
    final currentUser = context.watch<AuthBloc>().state.user ??
        const UserModel(
          id: 'USR-01',
          fullName: 'Carrier',
          email: 'carrier@logiflow.uz',
          phone: '+998 90 000 00 00',
          role: UserRole.carrier,
        );

    final bids = widget.shipment.bids;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'bidding.title'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                StatusBadge(
                  label: widget.shipment.trackingCode,
                  color: AppColors.primary,
                  fontSize: 11,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Initial Budget vs Negotiation Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bidding.initialBudget'.tr(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currencyFormatter.format(widget.shipment.price)} UZS',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${bids.length} Active Bids',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bids & Negotiation Audit Trail
            Text(
              'bidding.history'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.darkTextMuted,
              ),
            ),
            const SizedBox(height: 10),

            if (bids.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No bids submitted yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
              )
            else
              ...bids.map((bid) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bid.isAccepted
                          ? AppColors.emerald
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bid.carrierName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          StatusBadge(
                            label: bid.negotiationStatus.labelKey.tr(),
                            color: bid.isAccepted ? AppColors.emerald : AppColors.amber,
                            fontSize: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bid.vehicleModel} • Rating: ${bid.carrierRating} ★',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${currencyFormatter.format(bid.bidAmount)} UZS',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                            ),
                          ),
                          if (currentUser.role == UserRole.shipper && !bid.isAccepted)
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isCounterMode = true;
                                      _counterController.text = (bid.bidAmount * 0.97).toStringAsFixed(0);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'bidding.counterBack'.tr(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    context.read<ShipmentBloc>().add(
                                          AcceptBidSubmitted(
                                            shipmentId: widget.shipment.id,
                                            bidId: bid.id,
                                          ),
                                        );
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'bidding.acceptOffer'.tr(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 12),

            // Carrier Submit Counter-Offer / Form
            if (currentUser.role == UserRole.carrier || _isCounterMode) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'bidding.negotiateRate'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _counterController,
                label: 'bidding.yourOffer'.tr(),
                hint: '14,000,000',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: _commentController,
                label: 'bidding.offerComment'.tr(),
                hint: 'Includes loading assistance and expedited delivery...',
                prefixIcon: const Icon(Icons.chat_outlined, size: 20),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'bidding.submitOffer'.tr(),
                onPressed: () {
                  final amount = double.tryParse(_counterController.text.replaceAll(',', '')) ??
                      (widget.shipment.price * 0.95);

                  context.read<ShipmentBloc>().add(
                        SubmitBidSubmitted(
                          shipmentId: widget.shipment.id,
                          bid: BidModel(
                            id: 'BID-${DateTime.now().millisecondsSinceEpoch % 1000}',
                            carrierId: currentUser.id,
                            carrierName: currentUser.companyName ?? currentUser.fullName,
                            driverName: 'Sardor Qosimov',
                            vehicleModel: 'Volvo FH16 (2023)',
                            plateNumber: '01 842 TAA',
                            bidAmount: amount,
                            carrierRating: currentUser.rating,
                            createdAt: DateTime.now(),
                          ),
                        ),
                      );

                  Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
