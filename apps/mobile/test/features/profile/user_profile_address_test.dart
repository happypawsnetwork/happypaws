import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';

void main() {
  group('UserProfile.hasHomeAddress', () {
    test('returns false when addressLine1 is null or empty', () {
      const profileNull = UserProfile(
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        roles: [],
        addressLine1: null,
        city: 'Colombo',
        state: 'Western',
      );
      expect(profileNull.hasHomeAddress, isFalse);

      const profileEmpty = UserProfile(
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        roles: [],
        addressLine1: '   ',
        city: 'Colombo',
        state: 'Western',
      );
      expect(profileEmpty.hasHomeAddress, isFalse);
    });

    test('returns false when city is null or empty', () {
      const profile = UserProfile(
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        roles: [],
        addressLine1: '123 Galle Road',
        city: '',
        state: 'Western',
      );
      expect(profile.hasHomeAddress, isFalse);
    });

    test('returns false when state/province is null or empty', () {
      const profile = UserProfile(
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        roles: [],
        addressLine1: '123 Galle Road',
        city: 'Colombo',
        state: null,
      );
      expect(profile.hasHomeAddress, isFalse);
    });

    test('returns true when addressLine1, city, and state are non-empty', () {
      const profile = UserProfile(
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        roles: [],
        addressLine1: '123 Galle Road',
        city: 'Colombo',
        state: 'Western',
      );
      expect(profile.hasHomeAddress, isTrue);
    });
  });
}
