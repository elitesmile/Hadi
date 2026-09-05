// اختبارات أساسية للتأكد من عمل واجهة اللعبة ومنطقها الأساسي.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thakirat_albilat/main.dart';
import 'package:thakirat_albilat/widgets/memory_tile.dart';

void main() {
  testWidgets('الشاشة الرئيسية تعرض العنوان وزر بدء اللعب', (WidgetTester tester) async {
    await tester.pumpWidget(const ThakiratAlbilatApp());

    expect(find.text('ذاكرة البلاطات'), findsOneWidget);
    expect(find.text('ابدأ اللعب'), findsOneWidget);
  });

  testWidgets('الضغط على "ابدأ اللعب" يفتح لوحة من 10 بلاطات مقلوبة', (WidgetTester tester) async {
    await tester.pumpWidget(const ThakiratAlbilatApp());

    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pumpAndSettle();

    expect(find.byType(MemoryTile), findsNWidgets(10));
    // كل البلاطات تبدأ مقلوبة (تعرض أيقونة الاستفهام على ظهرها).
    expect(find.byIcon(Icons.help_outline_rounded), findsNWidgets(10));
  });

  testWidgets('الضغط على بلاطة واحدة يقلبها لتُظهر وجهها', (WidgetTester tester) async {
    await tester.pumpWidget(const ThakiratAlbilatApp());
    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MemoryTile).first);
    await tester.pumpAndSettle();

    // بلاطة واحدة أصبحت مكشوفة، فتبقى 9 فقط تُظهر ظهر البلاطة.
    expect(find.byIcon(Icons.help_outline_rounded), findsNWidgets(9));
  });
}
