import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uvita_courier/theme.dart';

void main() {
  test('Courier OS palitrasi mavjud', () {
    expect(AppColors.primary, isNotNull);
    expect(AppColors.background, isNotNull);
    expect(AppColors.surface, isNotNull);
    expect(AppColors.success, isNotNull);
    expect(AppColors.danger, isNotNull);
  });

  testWidgets('MaterialApp Courier OS tema bilan ishga tushadi',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const Scaffold()),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
