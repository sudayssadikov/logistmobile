import '../../../../core/network/api_result.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<ApiResult<UserModel>> loginWithPassword({
    required String emailOrPhone,
    required String password,
    required UserRole role,
  });

  Future<ApiResult<UserModel>> registerUser({
    required UserModel user,
    required String password,
  });

  Future<ApiResult<bool>> sendOtp({required String phone});

  Future<ApiResult<UserModel>> verifyOtp({
    required String phone,
    required String otp,
    required UserRole role,
  });

  Future<ApiResult<UserModel>> biometricLogin({required UserRole role});

  Future<ApiResult<UserModel>> switchRole(UserRole newRole);

  Future<ApiResult<UserModel>> updateProfile(UserModel updatedUser);

  Future<ApiResult<UserModel?>> getCurrentUser();

  Future<void> logout();
}
