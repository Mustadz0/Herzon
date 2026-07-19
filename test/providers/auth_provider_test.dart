import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/data/models/user_model.dart';
import 'package:herzon/presentation/providers/auth_provider.dart';

void main() {
  group('AppAuthState', () {
    test('default state is not authenticated', () {
      const state = AppAuthState();
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
      expect(state.user, isNull);
      expect(state.error, isNull);
    });

    test('isAuthenticated returns true when user is set', () {
      const user = UserModel(id: 'user-1', isAnonymous: false);
      const state = AppAuthState(user: user);
      expect(state.isAuthenticated, true);
    });

    test('isAnonymous returns true when privacy setting is set', () {
      const user = UserModel(
        id: 'user-1',
        privacySettings: {'is_anonymous': true},
      );
      const state = AppAuthState(user: user);
      expect(state.isAnonymous, true);
    });

    test('error state', () {
      const state = AppAuthState(error: 'Auth failed');
      expect(state.error, 'Auth failed');
      expect(state.isAuthenticated, false);
    });
  });
}
