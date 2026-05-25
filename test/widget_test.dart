import 'package:film_maker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FilmMakerApp());

    expect(find.text('Film Maker Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
