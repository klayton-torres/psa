import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:peladeiros_sa/main.dart';
import 'package:peladeiros_sa/services/app_preferences_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('App inicializa sem erros', (WidgetTester tester) async {
    final prefs = AppPreferencesService();
    await prefs.init();
    await tester.pumpWidget(PeladeirosApp(prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.text('Peladeiros S/A'), findsWidgets);
  });
}
