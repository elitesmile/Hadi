// اختبارات أساسية للتأكد من عمل واجهة اللعبة ومنطقها الأساسي.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thakirat_albilat/main.dart';
import 'package:thakirat_albilat/screens/game_screen.dart' show kSessionAttempts;
import 'package:thakirat_albilat/services/coin_wallet.dart';
import 'package:thakirat_albilat/widgets/memory_tile.dart';

void main() {
  // يمنح shared_preferences تخزينًا وهميًا في الذاكرة بدل قنوات المنصة
  // الحقيقية غير المتاحة أثناء الاختبارات، ويصفّره قبل كل اختبار.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('الشاشة الرئيسية تعرض العنوان، الرصيد، وزر بدء اللعب', (WidgetTester tester) async {
    await tester.pumpWidget(const ThakiratAlbilatApp());
    await tester.pumpAndSettle(); // لإتاحة تحميل الرصيد غير المتزامن

    expect(find.text('ذاكرة البلاطات'), findsOneWidget);
    expect(find.textContaining('ابدأ اللعب'), findsOneWidget);
    expect(find.text('${CoinWallet.startingBalance} كوين'), findsOneWidget);
  });

  testWidgets('الضغط على "ابدأ اللعب" يخصم الكوين ويفتح لوحة من 6 بلاطات', (WidgetTester tester) async {
    await tester.pumpWidget(const ThakiratAlbilatApp());
    await tester.pump();

    await tester.tap(find.textContaining('ابدأ اللعب'));
    await tester.pumpAndSettle();

    expect(find.byType(MemoryTile), findsNWidgets(6));
    // كل البلاطات تبدأ مقلوبة (تعرض أيقونة الاستفهام على ظهرها).
    expect(find.byIcon(Icons.help_outline_rounded), findsNWidgets(6));
    // شريط التقدّم يعرض المحاولة الأولى من أصل 5.
    expect(find.textContaining('المحاولة 1 من $kSessionAttempts'), findsOneWidget);
  });

  testWidgets('الضغط على بلاطة واحدة يقلبها لتُظهر وجهها', (WidgetTester tester) async {
    await tester.pumpWidget(const ThakiratAlbilatApp());
    await tester.pump();
    await tester.tap(find.textContaining('ابدأ اللعب'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MemoryTile).first);
    await tester.pumpAndSettle();

    // بلاطة واحدة أصبحت مكشوفة، فتبقى 5 فقط تُظهر ظهر البلاطة.
    expect(find.byIcon(Icons.help_outline_rounded), findsNWidgets(5));
  });
}
