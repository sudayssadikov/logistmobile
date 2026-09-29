import 'package:equatable/equatable.dart';
import '../../domain/models/wallet_model.dart';

enum WalletStateStatus { initial, loading, success, actionSuccess, error }

class WalletState extends Equatable {
  final WalletStateStatus status;
  final WalletModel? wallet;
  final String? errorMessage;
  final String? successMessage;

  const WalletState({
    this.status = WalletStateStatus.initial,
    this.wallet,
    this.errorMessage,
    this.successMessage,
  });

  WalletState copyWith({
    WalletStateStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    String? successMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, wallet, errorMessage, successMessage];
}
