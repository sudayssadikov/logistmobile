import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class FetchWalletSummaryRequested extends WalletEvent {}

class DepositFundsSubmitted extends WalletEvent {
  final double amount;
  const DepositFundsSubmitted(this.amount);
  @override
  List<Object?> get props => [amount];
}

class WithdrawFundsSubmitted extends WalletEvent {
  final double amount;
  final String cardNumber;
  const WithdrawFundsSubmitted({required this.amount, required this.cardNumber});
  @override
  List<Object?> get props => [amount, cardNumber];
}
