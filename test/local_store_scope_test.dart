import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoice_easy/services/local_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.initialize();
  });

  test('anonymous data migrates to a new user scope once', () async {
    await LocalStore.writeObject('profile', {'name': 'Anonymous Business'});

    final migrated = await LocalStore.switchToUserScope('user-a');

    expect(migrated, isTrue);
    expect(LocalStore.currentScope, 'user-a');
    expect(await LocalStore.readObject('profile'), {'name': 'Anonymous Business'});
  });

  test('all anonymous keys migrate, including newly introduced keys', () async {
    await LocalStore.writeObject('future_feature', {'enabled': true});
    await LocalStore.writeList('future_items', [
      {'id': '1', 'name': 'Item'},
    ]);

    final migrated = await LocalStore.switchToUserScope('user-a');

    expect(migrated, isTrue);
    expect(await LocalStore.readObject('future_feature'), {'enabled': true});
    expect(await LocalStore.readList('future_items'), [
      {'id': '1', 'name': 'Item'},
    ]);
  });

  test('anonymous migration does not overwrite existing user data', () async {
    await LocalStore.writeObject('profile', {'name': 'Anonymous Business'});
    await LocalStore.switchToUserScope('user-a');
    await LocalStore.writeObject('profile', {'name': 'Business A'});

    await LocalStore.switchToAnonymousScope();
    await LocalStore.writeObject('new_anonymous_data', {'value': 42});

    final migrated = await LocalStore.switchToUserScope('user-a');

    expect(migrated, isTrue);
    expect(await LocalStore.readObject('profile'), {'name': 'Business A'});
    expect(await LocalStore.readObject('new_anonymous_data'), {'value': 42});
  });

  test('switching users isolates previously stored user data', () async {
    await LocalStore.switchToUserScope('user-a');
    await LocalStore.writeObject('profile', {'name': 'Business A'});

    await LocalStore.switchToUserScope('user-b');

    expect(await LocalStore.readObject('profile'), isNull);
  });

  test('switching back to a known user restores that user scope', () async {
    await LocalStore.switchToUserScope('user-a');
    await LocalStore.writeObject('profile', {'name': 'Business A'});

    await LocalStore.switchToUserScope('user-b');
    await LocalStore.writeObject('profile', {'name': 'Business B'});

    await LocalStore.switchToUserScope('user-a');

    expect(await LocalStore.readObject('profile'), {'name': 'Business A'});
  });
}
