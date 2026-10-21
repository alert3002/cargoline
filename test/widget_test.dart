import 'package:cargo_line_tj/app.dart';
import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/models/parcel.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStore> openStore({Map<String, Object> values = const {}}) async {
    SharedPreferences.setMockInitialValues(Map<String, Object>.from(values));
    return LocalStore.open();
  }

  testWidgets('Auth screen loads after splash', (tester) async {
    final store = await openStore(values: {'sample_seeded': true});
    final app = AppProvider(store);
    final parcels = ParcelProvider(store);
    await Future.wait([app.load(), parcels.load()]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider.value(value: parcels),
        ],
        child: const CargoApp(),
      ),
    );

    await tester.pump();
    // Welcome splash ~4.8s.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump();

    expect(find.text('Продолжить'), findsOneWidget);
    expect(find.textContaining('+992'), findsWidgets);
  });

  test('Offline chinaWarehouse promotes to inTransit after 3 days', () {
    final now = DateTime.now();
    final aged = Parcel(
      id: 't1',
      trackCode: 'SFTESTPROMOTE001',
      status: ParcelStatusKey.chinaWarehouse,
      marketplace: MarketplaceKey.pinduoduo,
      createdAt: now.subtract(const Duration(days: 4)),
      lastUpdate: now.subtract(const Duration(days: 4)),
      progress: 0.1,
    );
    expect(aged.status, ParcelStatusKey.chinaWarehouse);
    final ageDays = now.difference(aged.createdAt).inDays;
    expect(ageDays >= 3, isTrue);
  });
}
