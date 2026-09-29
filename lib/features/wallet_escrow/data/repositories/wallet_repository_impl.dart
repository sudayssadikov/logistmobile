import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/wallet_model.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements IWalletRepository {
  final DioClient? _dioClient;
  late WalletModel _wallet;

  WalletRepositoryImpl([this._dioClient]) {
    _wallet = WalletModel(
      availableBalance: 42500000.0,
      inEscrowHoldBalance: 28000000.0,
      pendingPayouts: 16500000.0,
      totalLifetimeEarnings: 312000000.0,
      transactions: [
        EscrowTransactionModel(
          id: 'TXN-8801',
          type: TransactionType.escrowRelease,
          title: 'wallet.txnRelease',
          trackingCode: 'LF-UZ-2100',
          amount: 18500000.0,
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        EscrowTransactionModel(
          id: 'TXN-8802',
          type: TransactionType.escrowHold,
          title: 'wallet.txnLock',
          trackingCode: 'LF-UZ-8921',
          amount: 16500000.0,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        EscrowTransactionModel(
          id: 'TXN-8803',
          type: TransactionType.deposit,
          title: 'wallet.txnDeposit',
          amount: 50000000.0,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
        EscrowTransactionModel(
          id: 'TXN-8804',
          type: TransactionType.payout,
          title: 'wallet.txnWithdraw',
          amount: 25000000.0,
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
        ),
        EscrowTransactionModel(
          id: 'TXN-8805',
          type: TransactionType.commission,
          title: 'wallet.txnFee',
          amount: 247500.0,
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
    );
  }

  @override
  Future<ApiResult<WalletModel>> getWalletSummary() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/wallet');
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data['data'];
          if (data != null) {
            _wallet = _wallet.copyWith(
              availableBalance: (data['available_balance'] as num?)?.toDouble() ?? _wallet.availableBalance,
              inEscrowHoldBalance: (data['in_escrow_balance'] as num?)?.toDouble() ?? _wallet.inEscrowHoldBalance,
              pendingPayouts: (data['pending_payouts'] as num?)?.toDouble() ?? _wallet.pendingPayouts,
              totalLifetimeEarnings: (data['lifetime_earnings'] as num?)?.toDouble() ?? _wallet.totalLifetimeEarnings,
            );
            return ApiSuccess(_wallet);
          }
        }
      } catch (_) {
        // Fallback to local
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    return ApiSuccess(_wallet);
  }

  @override
  Future<ApiResult<WalletModel>> depositFunds(double amount) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post(
          '/payments/create-intent',
          data: {
            'provider': 'payme',
            'amount': amount,
            'description': 'LogiFlow Balance Top-up',
          },
        );
        if (response.statusCode == 200) {
          // Success intent generated
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final newTxn = EscrowTransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.deposit,
      title: 'Direct Card Top-up',
      amount: amount,
      timestamp: DateTime.now(),
    );
    final updatedList = List<EscrowTransactionModel>.from(_wallet.transactions)..insert(0, newTxn);
    _wallet = _wallet.copyWith(
      availableBalance: _wallet.availableBalance + amount,
      transactions: updatedList,
    );
    return ApiSuccess(_wallet);
  }

  @override
  Future<ApiResult<WalletModel>> requestWithdrawal(double amount, String cardNumber) async {
    if (amount > _wallet.availableBalance) {
      return const ApiFailure(message: 'Yetarli mavjud balans mavjud emas.');
    }

    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post(
          '/wallet/withdraw',
          data: {'amount': amount, 'card_number': cardNumber},
        );
        if (response.statusCode == 200) {
          // Success on backend
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final newTxn = EscrowTransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.payout,
      title: 'Withdrawal to $cardNumber',
      amount: amount,
      timestamp: DateTime.now(),
    );
    final updatedList = List<EscrowTransactionModel>.from(_wallet.transactions)..insert(0, newTxn);
    _wallet = _wallet.copyWith(
      availableBalance: _wallet.availableBalance - amount,
      transactions: updatedList,
    );
    return ApiSuccess(_wallet);
  }

  @override
  Future<ApiResult<WalletModel>> releaseEscrowHold(String transactionId) async {
    if (_dioClient != null) {
      try {
        await _dioClient!.post('/wallet/escrow/release', data: {'transaction_id': transactionId});
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    return ApiSuccess(_wallet);
  }
}
