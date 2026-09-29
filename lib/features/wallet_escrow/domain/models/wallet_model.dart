import 'package:equatable/equatable.dart';

enum TransactionType {
  deposit('Deposit', '+'),
  escrowHold('Escrow Hold', '🔒'),
  escrowRelease('Escrow Release', '✓'),
  payout('Payout Withdrawal', '-'),
  commission('Platform Fee', '-');

  final String label;
  final String symbol;
  const TransactionType(this.label, this.symbol);
}

class EscrowTransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final String title;
  final String? trackingCode;
  final double amount;
  final DateTime timestamp;
  final bool isCompleted;

  const EscrowTransactionModel({
    required this.id,
    required this.type,
    required this.title,
    this.trackingCode,
    required this.amount,
    required this.timestamp,
    this.isCompleted = true,
  });

  @override
  List<Object?> get props => [id, type, title, trackingCode, amount, timestamp, isCompleted];
}

class WalletModel extends Equatable {
  final double availableBalance;
  final double inEscrowHoldBalance;
  final double pendingPayouts;
  final double totalLifetimeEarnings;
  final List<EscrowTransactionModel> transactions;

  const WalletModel({
    required this.availableBalance,
    required this.inEscrowHoldBalance,
    required this.pendingPayouts,
    required this.totalLifetimeEarnings,
    this.transactions = const [],
  });

  WalletModel copyWith({
    double? availableBalance,
    double? inEscrowHoldBalance,
    double? pendingPayouts,
    double? totalLifetimeEarnings,
    List<EscrowTransactionModel>? transactions,
  }) {
    return WalletModel(
      availableBalance: availableBalance ?? this.availableBalance,
      inEscrowHoldBalance: inEscrowHoldBalance ?? this.inEscrowHoldBalance,
      pendingPayouts: pendingPayouts ?? this.pendingPayouts,
      totalLifetimeEarnings: totalLifetimeEarnings ?? this.totalLifetimeEarnings,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  List<Object?> get props => [
        availableBalance,
        inEscrowHoldBalance,
        pendingPayouts,
        totalLifetimeEarnings,
        transactions,
      ];
}
