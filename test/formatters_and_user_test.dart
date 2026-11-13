import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/core/storage/local_storage_service.dart';
import 'package:logiflow_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:logiflow_mobile/features/auth/domain/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Role & Model Tests', () {
    test('UserRole keys resolve correctly', () {
      expect(UserRole.fromKey('shipper'), UserRole.shipper);
      expect(UserRole.fromKey('carrier'), UserRole.shipper);
      expect(UserRole.fromKey('driver'), UserRole.driver);
      expect(UserRole.fromKey('truck_driver'), UserRole.driver);
      expect(UserRole.fromKey('unknown'), UserRole.shipper);
    });

    test('UserModel serialization roundtrip', () {
      const user = UserModel(
        id: 'USR-TEST-01',
        fullName: 'Test Logistics User',
        email: 'test@logiflow.uz',
        phone: '+998 90 123 45 67',
        role: UserRole.driver,
        companyName: 'Express Fleet LLC',
        isVerified: true,
        rating: 4.85,
        completedTrips: 50,
        walletBalance: 12000000.0,
      );

      final json = user.toJson();
      final fromJson = UserModel.fromJson(json);

      expect(fromJson.id, user.id);
      expect(fromJson.fullName, user.fullName);
      expect(fromJson.role, UserRole.driver);
      expect(fromJson.walletBalance, 12000000.0);
    });

    test('AuthRepository returns ApiFailure when disconnected without mock backdoor', () async {
      final storage = LocalStorageService();
      final authRepo = AuthRepositoryImpl(storage);

      final result = await authRepo.loginWithPassword(
        emailOrPhone: 'sudaysadmin',
        password: 'sudaysbrat1109',
        role: UserRole.shipper,
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isNotNull);
    });
  });
}
