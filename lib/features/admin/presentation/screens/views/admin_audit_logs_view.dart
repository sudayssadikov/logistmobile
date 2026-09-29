import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_dashboard_bloc.dart';
import '../../widgets/audit_log_tile.dart';

class AdminAuditLogsView extends StatelessWidget {
  const AdminAuditLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        final logs = state.recentAuditLogs;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AdminDashboardBloc>().add(AdminRefreshKpiEvent());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return AuditLogTile(log: logs[index]);
            },
          ),
        );
      },
    );
  }
}
