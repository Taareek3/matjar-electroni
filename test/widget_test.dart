import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_customer_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App renders the home menu screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RestaurantCustomerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('المنيو'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
