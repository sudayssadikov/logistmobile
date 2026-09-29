import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final IWalletRepository _walletRepository;

  WalletBloc(this._walletRepository) : super(const WalletState()) {
    on<FetchWalletSummaryRequested>(_onFetchWalletSummaryRequested);
    on<DepositFundsSubmitted>(_onDepositFundsSubmitted);
    on<WithdrawFundsSubmitted>(_onWithdrawFundsSubmitted);
  }

  Future<void> _onFetchWalletSummaryRequested(
    FetchWalletSummaryRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStateStatus.loading));
    final result = await _walletRepository.getWalletSummary();
    result.when(
      success: (data) {
        emit(state.copyWith(
          status: WalletStateStatus.success,
          wallet: data,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: WalletStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onDepositFundsSubmitted(
    DepositFundsSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStateStatus.loading));
    final result = await _walletRepository.depositFunds(event.amount);
    result.when(
      success: (data) {
        emit(state.copyWith(
          status: WalletStateStatus.actionSuccess,
          wallet: data,
          successMessage: 'Deposit completed successfully!',
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: WalletStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onWithdrawFundsSubmitted(
    WithdrawFundsSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStateStatus.loading));
    final result = await _walletRepository.requestWithdrawal(event.amount, event.cardNumber);
    result.when(
      success: (data) {
        emit(state.copyWith(
          status: WalletStateStatus.actionSuccess,
          wallet: data,
          successMessage: 'Withdrawal payout processed!',
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: WalletStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }
}
