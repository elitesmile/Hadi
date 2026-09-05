// اختبارات وحدة لمحفظة الكوينز: الخصم، الشحن، والجائزة الافتراضية.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thakirat_albilat/services/coin_wallet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('الرصيد الافتراضي يساوي startingBalance قبل أي عملية', () async {
    expect(await CoinWallet.getBalance(), CoinWallet.startingBalance);
  });

  test('خصم تكلفة الجلسة ينجح وينقص الرصيد بمقدار costPerSession', () async {
    final newBalance = await CoinWallet.trySpendSessionCost();
    expect(newBalance, CoinWallet.startingBalance - CoinWallet.costPerSession);
    expect(await CoinWallet.getBalance(), CoinWallet.startingBalance - CoinWallet.costPerSession);
  });

  test('خصم تكلفة الجلسة يفشل (يُرجع null) عند عدم كفاية الرصيد', () async {
    // نستهلك كل الرصيد تقريبًا حتى يصبح أقل من التكلفة المطلوبة.
    while ((await CoinWallet.getBalance()) >= CoinWallet.costPerSession) {
      await CoinWallet.trySpendSessionCost();
    }
    final remaining = await CoinWallet.getBalance();
    final result = await CoinWallet.trySpendSessionCost();
    expect(result, isNull);
    // الرصيد لا يتغيّر عند فشل الخصم.
    expect(await CoinWallet.getBalance(), remaining);
  });

  test('addCoins يزيد الرصيد بالمقدار المطلوب (شراء أو جائزة)', () async {
    final newBalance = await CoinWallet.addCoins(CoinWallet.challengeRewardCoins);
    expect(newBalance, CoinWallet.startingBalance + CoinWallet.challengeRewardCoins);
  });
}
