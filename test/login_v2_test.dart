import 'package:cashflow_app/src/pages/login_v2.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = {
    '320x568': Size(320, 568),
    '360x640': Size(360, 640),
    '412x915': Size(412, 915),
    '800x1280': Size(800, 1280),
  };

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final entry in sizes.entries) {
      testWidgets('LoginV2 sem estouro de layout ($mode, ${entry.key})',
          (tester) async {
        tester.view.physicalSize = entry.value * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        AppSettings.themeModeV2.value = mode;

        await tester.pumpWidget(const MaterialApp(home: LoginV2()));
        await tester.pumpAndSettle();

        final brightness =
            Theme.of(tester.element(find.text('Entrar'))).brightness;
        expect(brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light);

        await tester.ensureVisible(find.text('Entrar'));
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();
        expect(find.text('Informe seu email'), findsOneWidget);
        expect(find.text('Informe sua senha'), findsOneWidget);

        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
