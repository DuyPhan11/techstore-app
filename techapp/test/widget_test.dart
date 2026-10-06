import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techapp/main.dart';
import 'package:techapp/providers/auth_provider.dart';
import 'package:techapp/providers/cart_provider.dart';
import 'package:techapp/providers/order_provider.dart';
import 'package:techapp/providers/product_provider.dart';
import 'package:techapp/providers/favorite_provider.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ],
        child: const TechStoreApp(),
      ),
    );

    expect(find.byType(TechStoreApp), findsOneWidget);
  });
}
