import 'package:dio/dio.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final ILocalStorageService _storage;
  final DioClient? _dioClient;

  AuthRepositoryImpl(this._storage, [this._dioClient]);

  @override
  Future<ApiResult<UserModel>> loginWithPassword({
    required String emailOrPhone,
    required String password,
    required UserRole role,
  }) async {
    final cleanInput = emailOrPhone.trim().toLowerCase();

    if (_dioClient == null) {
      return const ApiFailure(message: 'Serverga ulanish imkoni bo\'lmadi. Internet aloqasini tekshiring.');
    }

    try {
      final response = await _dioClient!.post(
        '/auth/login',
        data: {
          'emailOrPhone': cleanInput,
          'password': password,
          'role': role.key,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final userData = data['user'];

        if (userData != null) {
          final user = UserModel.fromJson(userData);

          // Qat'iy tekshiruv: agar akkaunt roli tanlangan rolga mos kelmasa, ruxsat bermaslik!
          if (user.role != role) {
            final mismatchMsg = user.role == UserRole.driver
                ? 'auth.roleMismatchDriver'.tr()
                : 'auth.roleMismatchShipper'.tr();
            return ApiFailure(message: mismatchMsg);
          }

          if (accessToken != null) await _storage.saveToken(accessToken);
          if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);
          await _storage.saveUserRole(user.role.key);
          await _storage.saveUserProfile(user.toJson());
          return ApiSuccess(user);
        }
      }
      return const ApiFailure(message: 'Tizimga kirishda kutilmagan xatolik yuz berdi');
    } on DioException catch (dioErr) {
      String? message;
      if (dioErr.response?.data is Map) {
        final data = dioErr.response!.data as Map;
        message = data['message'] as String? ?? data['detail'] as String?;
      }
      return ApiFailure(
        message: message ?? dioErr.message ?? 'Server bilan aloqa o\'rnatib bo\'lmadi',
        statusCode: dioErr.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(message: 'Tizimga kirishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<UserModel>> registerUser({
    required UserModel user,
    required String password,
  }) async {
    final cleanEmail = user.email.trim().toLowerCase();
    final cleanPhone = user.phone.trim().replaceAll(' ', '');

    if (_dioClient == null) {
      return const ApiFailure(message: 'Serverga ulanish imkoni bo\'lmadi. Internet aloqasini tekshiring.');
    }

    try {
      final response = await _dioClient!.post(
        '/auth/register',
        data: {
          'fullName': user.fullName,
          'email': cleanEmail.isNotEmpty ? cleanEmail : 'user_${DateTime.now().millisecondsSinceEpoch}@logiflow.uz',
          'phone': cleanPhone,
          'password': password,
          'role': user.role.key,
          'companyName': user.companyName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          final data = response.data['data'];
          final accessToken = data['access_token'];
          final refreshToken = data['refresh_token'];
          final userData = data['user'];

          if (userData != null) {
            final registeredUser = UserModel.fromJson(userData);
            if (accessToken != null) await _storage.saveToken(accessToken);
            if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);
            await _storage.saveUserRole(registeredUser.role.key);
            await _storage.saveUserProfile(registeredUser.toJson());
            return ApiSuccess(registeredUser);
          }
        }
      }
      return const ApiFailure(message: 'Ro\'yxatdan o\'tishda kutilmagan xatolik yuz berdi');
    } on DioException catch (dioErr) {
      String? message;
      if (dioErr.response?.data is Map) {
        final data = dioErr.response!.data as Map;
        message = data['message'] as String? ?? data['detail'] as String?;
      }
      return ApiFailure(
        message: message ?? dioErr.message ?? 'Server bilan aloqa o\'rnatib bo\'lmadi',
        statusCode: dioErr.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(message: 'Ro\'yxatdan o\'tishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<bool>> sendOtp({required String phone}) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Serverga ulanish imkoni bo\'lmadi. Internet aloqasini tekshiring.');
    }

    try {
      final response = await _dioClient!.post(
        '/auth/send-otp',
        data: {'phone': phone.trim().replaceAll(' ', '')},
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(true);
      }
      return const ApiFailure(message: 'SMS kod yuborishda xatolik');
    } on DioException catch (dioErr) {
      String? message;
      if (dioErr.response?.data is Map) {
        final data = dioErr.response!.data as Map;
        message = data['message'] as String? ?? data['detail'] as String?;
      }
      return ApiFailure(
        message: message ?? dioErr.message ?? 'Server bilan aloqa o\'rnatib bo\'lmadi',
        statusCode: dioErr.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(message: 'SMS kod yuborishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<UserModel>> verifyOtp({
    required String phone,
    required String otp,
    required UserRole role,
  }) async {
    final cleanPhone = phone.trim().replaceAll(' ', '');

    if (_dioClient == null) {
      return const ApiFailure(message: 'Serverga ulanish imkoni bo\'lmadi. Internet aloqasini tekshiring.');
    }

    try {
      final response = await _dioClient!.post(
        '/auth/verify-otp',
        data: {
          'phone': cleanPhone,
          'otp': otp,
          'role': role.key,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final userData = data['user'];

        if (userData != null) {
          final user = UserModel.fromJson(userData);
          if (user.role != role) {
            final mismatchMsg = user.role == UserRole.driver
                ? 'auth.roleMismatchDriver'.tr()
                : 'auth.roleMismatchShipper'.tr();
            return ApiFailure(message: mismatchMsg);
          }
          if (accessToken != null) await _storage.saveToken(accessToken);
          if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);
          await _storage.saveUserRole(user.role.key);
          await _storage.saveUserProfile(user.toJson());
          return ApiSuccess(user);
        }
      }
      return const ApiFailure(message: 'SMS kod tasdiqlashda xatolik');
    } on DioException catch (dioErr) {
      String? message;
      if (dioErr.response?.data is Map) {
        final data = dioErr.response!.data as Map;
        message = data['message'] as String? ?? data['detail'] as String?;
      }
      return ApiFailure(
        message: message ?? dioErr.message ?? 'Server bilan aloqa o\'rnatib bo\'lmadi',
        statusCode: dioErr.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(message: 'SMS kod tasdiqlashda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<UserModel>> biometricLogin({required UserRole role}) async {
    final profile = await _storage.getUserProfile();
    final token = await _storage.getToken();
    if (profile != null && token != null) {
      final user = UserModel.fromJson(profile);
      if (user.role != role) {
        final mismatchMsg = user.role == UserRole.driver
            ? 'auth.roleMismatchDriver'.tr()
            : 'auth.roleMismatchShipper'.tr();
        return ApiFailure(message: mismatchMsg);
      }
      return ApiSuccess(user);
    }
    return const ApiFailure(message: 'Avval akkauntingizga kiring');
  }

  @override
  Future<ApiResult<UserModel>> switchRole(UserRole newRole) async {
    return const ApiFailure(message: 'Bitta akkaunt = bitta rol. Rolni almashtirib bo\'lmaydi.');
  }

  @override
  Future<ApiResult<UserModel?>> getCurrentUser() async {
    final token = await _storage.getToken();
    if (token == null) {
      return const ApiSuccess(null);
    }
    final profile = await _storage.getUserProfile();
    if (profile != null) {
      return ApiSuccess(UserModel.fromJson(profile));
    }
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<UserModel>> updateProfile(UserModel updatedUser) async {
    if (_dioClient != null) {
      try {
        await _dioClient!.put(
          '/users/me',
          data: updatedUser.toJson(),
        );
      } catch (_) {
        // Fall through to update local cache
      }
    }
    await _storage.saveUserProfile(updatedUser.toJson());
    return ApiSuccess(updatedUser);
  }

  @override
  Future<void> logout() async {
    await _storage.clearAuthData();
  }
}
