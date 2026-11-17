import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/storage/cache_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  group('LocalPasscodeCubit Tests', () {
    test('initial state has isEnabled=false and isLocked=false', () {
      final cubit = LocalPasscodeCubit();
      expect(cubit.state.isEnabled, isFalse);
      expect(cubit.state.isLocked, isFalse);
      expect(cubit.state.autoLockMinutes, equals(5));
      cubit.close();
    });

    test('setting passcode succeeds and enables lock protection', () async {
      final cubit = LocalPasscodeCubit();
      final success = await cubit.setPasscode('1234');
      expect(success, isTrue);
      expect(cubit.state.isEnabled, isTrue);
      expect(cubit.state.isLocked, isFalse);
      cubit.close();
    });

    test('locking app changes isLocked to true', () async {
      final cubit = LocalPasscodeCubit();
      await cubit.setPasscode('1234');
      cubit.lock();
      expect(cubit.state.isLocked, isTrue);

      // Wrong passcode fails unlock
      final failed = cubit.unlock('9999');
      expect(failed, isFalse);
      expect(cubit.state.isLocked, isTrue);
      expect(cubit.state.errorMessage, isNotNull);

      // Correct passcode unlocks
      final unlocked = cubit.unlock('1234');
      expect(unlocked, isTrue);
      expect(cubit.state.isLocked, isFalse);
      cubit.close();
    });

    test('changing passcode requires valid old passcode', () async {
      final cubit = LocalPasscodeCubit();
      await cubit.setPasscode('1234');

      final failChange = await cubit.changePasscode(
        oldPasscode: '0000',
        newPasscode: '5678',
      );
      expect(failChange, isFalse);

      final okChange = await cubit.changePasscode(
        oldPasscode: '1234',
        newPasscode: '5678',
      );
      expect(okChange, isTrue);

      cubit.lock();
      expect(cubit.unlock('1234'), isFalse);
      expect(cubit.unlock('5678'), isTrue);
      cubit.close();
    });

    test('disabling passcode clears stored code and state', () async {
      final cubit = LocalPasscodeCubit();
      await cubit.setPasscode('1234');
      expect(cubit.state.isEnabled, isTrue);

      final disabled = await cubit.disablePasscode('1234');
      expect(disabled, isTrue);
      expect(cubit.state.isEnabled, isFalse);
      expect(cubit.state.isLocked, isFalse);
      cubit.close();
    });
  });
}
