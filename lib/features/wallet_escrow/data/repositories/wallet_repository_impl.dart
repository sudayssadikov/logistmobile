import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/wallet_model.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements IWalletRepository {
  final DioClient? _dioClient;
  WalletModel _wallet = const WalletModel(
    availableBalance: 0.0,
    inEscrowHoldBalance: 0.0,
    pendingPayouts: 0.0,
    totalLifetimeEarnings: 0.0,
    transactions: [],
  );

  WalletRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<WalletModel>> getWalletSummary() async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/wallet');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          // Fetch transactions as well
          List<EscrowTransactionModel> txns = [];
          try {
            final txnRes = await _dioClient!.get('/wallet/transactions');
            if (txnRes.statusCode == 200 && txnRes.data != null) {
              final List rawTxns = txnRes.data['data'] ?? [];
              txns = rawTxns.map((t) {
                final m = t as Map<String, dynamic>;
                return EscrowTransactionModel(
                  id: m['id'] ?? '',
                  type: TransactionType.values.firstWhere(
                    (e) => e.name.toLowerCase() == (m['type'] as String? ?? '').toLowerCase(),
                    orElse: () => TransactionType.deposit,
                  ),
                  title: m['title'] ?? 'Tranzaksiya',
                  amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
                  trackingCode: m['tracking_code'],
                  timestamp: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
                );
              }).toList();
            }
          } catch (_) {}

          _wallet = WalletModel(
            availableBalance: (data['available_balance'] as num?)?.toDouble() ?? 0.0,
            inEscrowHoldBalance: (data['in_escrow_balance'] as num?)?.toDouble() ?? 0.0,
            pendingPayouts: (data['pending_payouts'] as num?)?.toDouble() ?? 0.0,
            totalLifetimeEarnings: (data['lifetime_earnings'] as num?)?.toDouble() ?? 0.0,
            transactions: txns,
          );
          return ApiSuccess(_wallet);
        }
      }
      return ApiFailure(message: response.data?['message'] ?? 'Hamyon ma\'lumotlarini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Hamyon ma\'lumotlarini yuklab bo\'lmadi: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<WalletModel>> depositFunds(double amount) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/payments/intent',
        data: {
          'provider': 'payme',
          'amount': amount,
          'description': 'LogiFlow Balance Top-up',
        },
      );
      if (response.statusCode == 200) {
        return await getWalletSummary();
      }
      return ApiFailure(message: response.data?['message'] ?? 'To\'lov jarayonini boshlab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'To\'lovda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<WalletModel>> requestWithdrawal(double amount, String cardNumber) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/wallet/withdraw',
        data: {'amount': amount, 'card_number': cardNumber},
      );
      if (response.statusCode == 200) {
        return await getWalletSummary();
      }
      return ApiFailure(message: response.data?['message'] ?? 'Mablag\' yechishda xatolik');
    } catch (e) {
      return ApiFailure(message: 'Mablag\' yechishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<WalletModel>> releaseEscrowHold(String transactionId) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/wallet/escrow/release',
        data: {'shipment_id': transactionId},
      );
      if (response.statusCode == 200) {
        return await getWalletSummary();
      }
      return ApiFailure(message: response.data?['message'] ?? 'Eskrou chiqarishda xatolik');
    } catch (e) {
      return ApiFailure(message: 'Eskrou chiqarishda xatolik: ${e.toString()}');
    }
  }
}
