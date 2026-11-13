import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/driver_dashboard_view.dart';
import '../widgets/shipper_dashboard_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final role = state.user?.role ?? state.selectedRole;
        switch (role) {
          case UserRole.shipper:
            return const ShipperDashboardView();
          case UserRole.driver:
            return const DriverDashboardView();
        }
      },
    );
  }
}
