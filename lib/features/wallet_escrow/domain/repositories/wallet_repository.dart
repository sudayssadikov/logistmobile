import '../../../../core/network/api_result.dart';
import '../models/wallet_model.dart';

abstract class IWalletRepository {
  Future<ApiResult<WalletModel>> getWalletSummary();
  Future<ApiResult<WalletModel>> depositFunds(double amount);
  Future<ApiResult<WalletModel>> requestWithdrawal(double amount, String cardNumber);
  Future<ApiResult<WalletModel>> releaseEscrowHold(String transactionId);
}
