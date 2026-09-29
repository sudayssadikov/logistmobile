import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import '../widgets/document_card.dart';
import '../widgets/upload_document_modal.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  @override
  void initState() {
    super.initState();
    final role = context.read<AuthBloc>().state.user?.role ?? UserRole.carrier;
    context.read<DocumentBloc>().add(LoadDocumentsRequested(role));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user ??
        const UserModel(
          id: 'USR-01',
          fullName: 'Carrier Operator',
          email: 'carrier@logiflow.uz',
          phone: '+998 90 000 00 00',
          role: UserRole.carrier,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('documents.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'documents.uploadDoc'.tr(),
            onPressed: () => UploadDocumentModal.show(context, user.role),
          ),
        ],
      ),
      body: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state.status == DocumentStateStatus.loading && state.documents.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 4,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(width: double.infinity, height: 110),
              ),
            );
          }

          final activeCount = state.activeDocs.length;
          final expiringCount = state.expiringSoonDocs.length;
          final expiredCount = state.expiredOrRejectedDocs.length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DocumentBloc>().add(LoadDocumentsRequested(user.role));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subtitle info
                  Text(
                    'documents.subtitle'.tr(),
                    style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'documents.active'.tr(),
                          value: '$activeCount',
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.emerald,
                          trendText: 'Verified',
                          isPositiveTrend: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          title: 'documents.expiringSoon'.tr(),
                          value: '$expiringCount',
                          icon: Icons.hourglass_top_rounded,
                          iconColor: AppColors.amber,
                          trendText: '< 30d',
                          isPositiveTrend: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          title: 'documents.expired'.tr(),
                          value: '$expiredCount',
                          icon: Icons.error_outline_rounded,
                          iconColor: AppColors.rose,
                          trendText: 'Action',
                          isPositiveTrend: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (state.documents.isEmpty)
                    EmptyStateView(
                      icon: Icons.folder_open_rounded,
                      title: 'common.noData'.tr(),
                      description: 'No verified logistics documents found for this role.',
                      actionText: 'documents.uploadDoc'.tr(),
                      onAction: () => UploadDocumentModal.show(context, user.role),
                    )
                  else ...[
                    Text(
                      'ALL COMPLIANCE DOCUMENTS (${state.documents.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...state.documents.map(
                      (doc) => DocumentCard(
                        document: doc,
                        onDelete: () {
                          context.read<DocumentBloc>().add(DeleteDocumentSubmitted(doc.id));
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UploadDocumentModal.show(context, user.role),
        icon: const Icon(Icons.upload_file_rounded),
        label: Text('documents.uploadDoc'.tr()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
