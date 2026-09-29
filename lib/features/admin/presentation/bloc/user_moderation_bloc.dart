import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/admin_user_item_model.dart';
import '../../domain/models/verification_request_model.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class UserModerationEvent extends Equatable {
  const UserModerationEvent();
  @override
  List<Object?> get props => [];
}

class FetchModerationDataEvent extends UserModerationEvent {
  final String? searchQuery;
  final UserRole? roleFilter;
  const FetchModerationDataEvent({this.searchQuery, this.roleFilter});
  @override
  List<Object?> get props => [searchQuery, roleFilter];
}

class ModerateKycDocumentEvent extends UserModerationEvent {
  final String requestId;
  final VerificationStatus status;
  final String? reason;

  const ModerateKycDocumentEvent({
    required this.requestId,
    required this.status,
    this.reason,
  });

  @override
  List<Object?> get props => [requestId, status, reason];
}

class ToggleUserSuspensionEvent extends UserModerationEvent {
  final String userId;
  final bool isSuspended;
  final String? reason;

  const ToggleUserSuspensionEvent({
    required this.userId,
    required this.isSuspended,
    this.reason,
  });

  @override
  List<Object?> get props => [userId, isSuspended, reason];
}

class UserModerationState extends Equatable {
  final bool isLoading;
  final List<VerificationRequestModel> pendingVerifications;
  final List<AdminUserItemModel> users;
  final String? actionSuccessMessage;
  final String? errorMessage;

  const UserModerationState({
    this.isLoading = false,
    this.pendingVerifications = const [],
    this.users = const [],
    this.actionSuccessMessage,
    this.errorMessage,
  });

  UserModerationState copyWith({
    bool? isLoading,
    List<VerificationRequestModel>? pendingVerifications,
    List<AdminUserItemModel>? users,
    String? actionSuccessMessage,
    String? errorMessage,
  }) {
    return UserModerationState(
      isLoading: isLoading ?? this.isLoading,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      users: users ?? this.users,
      actionSuccessMessage: actionSuccessMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        pendingVerifications,
        users,
        actionSuccessMessage,
        errorMessage,
      ];
}

class UserModerationBloc extends Bloc<UserModerationEvent, UserModerationState> {
  final IAdminRepository _repository;

  UserModerationBloc({required IAdminRepository repository})
      : _repository = repository,
        super(const UserModerationState()) {
    on<FetchModerationDataEvent>(_onFetchData);
    on<ModerateKycDocumentEvent>(_onModerateKyc);
    on<ToggleUserSuspensionEvent>(_onToggleSuspension);
  }

  Future<void> _onFetchData(
    FetchModerationDataEvent event,
    Emitter<UserModerationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final kycRes = await _repository.getPendingVerifications();
    final usersRes = await _repository.getUsers(
      search: event.searchQuery,
      roleFilter: event.roleFilter,
    );

    emit(state.copyWith(
      isLoading: false,
      pendingVerifications: kycRes.dataOrNull ?? [],
      users: usersRes.dataOrNull ?? [],
    ));
  }

  Future<void> _onModerateKyc(
    ModerateKycDocumentEvent event,
    Emitter<UserModerationState> emit,
  ) async {
    final res = await _repository.moderateVerification(
      event.requestId,
      event.status,
      reason: event.reason,
    );

    if (res.isSuccess) {
      final updatedList = state.pendingVerifications.map((k) {
        if (k.id == event.requestId) {
          return k.copyWith(status: event.status, rejectionReason: event.reason);
        }
        return k;
      }).toList();

      emit(state.copyWith(
        pendingVerifications: updatedList,
        actionSuccessMessage: 'Hujjat holati ${event.status.label} ga o\'zgartirildi',
      ));
    }
  }

  Future<void> _onToggleSuspension(
    ToggleUserSuspensionEvent event,
    Emitter<UserModerationState> emit,
  ) async {
    final res = await _repository.toggleUserStatus(
      event.userId,
      isSuspended: event.isSuspended,
      reason: event.reason,
    );

    if (res.isSuccess) {
      final updatedUsers = state.users.map((u) {
        if (u.id == event.userId) {
          return u.copyWith(isSuspended: event.isSuspended);
        }
        return u;
      }).toList();

      emit(state.copyWith(
        users: updatedUsers,
        actionSuccessMessage: event.isSuspended ? 'Foydalanuvchi hisobi bloklandi' : 'Hisob faollashtirildi',
      ));
    }
  }
}
