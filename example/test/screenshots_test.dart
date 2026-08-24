// Renders the README screenshots from the real widgets, so they can be
// regenerated whenever the slider changes:
//
//   cd example && flutter test --update-goldens test/screenshots_test.dart
//
// The images land in ../../screenshots/ and are shown in README.md.
import 'dart:io';

import 'package:diamond_percent_slider/diamond_percent_slider.dart';
import 'package:diamond_percent_slider_example/demo_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// `flutter test` renders text with the placeholder Ahem font unless real
/// fonts are registered, so load the ones the slider actually draws with.
Future<void> _loadFonts() async {
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final String fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, String path) async {
    final File file = File(path);
    if (!file.existsSync()) return;
    await (FontLoader(family)..addFont(
          file.readAsBytes().then((Uint8List b) => ByteData.view(b.buffer)),
        ))
        .load();
  }

  await load('Roboto', '$fonts/Roboto-Regular.ttf');
  await load('MaterialIcons', '$fonts/MaterialIcons-Regular.otf');
}

/// The widgets on a plain backdrop, at the width they are shown at.
Widget _canvas(
  List<Widget> children, {
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildDemoTheme(brightness),
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 26,
          children: children,
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadFonts);

  testWidgets('the slider, at three settings', (WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(880, 520)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _canvas(<Widget>[
        DiamondPercentSlider(value: 25, onChanged: (_) {}),
        DiamondPercentSlider(
          value: 60,
          showLabels: true,
          onChanged: (_) {},
        ),
        DiamondPercentSlider(
          value: 20,
          min: 1,
          max: 100,
          showLabels: true,
          labelFormatter: (int value) => '${value}x',
          onChanged: (_) {},
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/slider.png'),
    );
  });

  testWidgets('coarse steps, a tint, and disabled', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(880, 520)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _canvas(<Widget>[
        DiamondPercentSlider(
          value: 50,
          step: 25,
          showLabels: true,
          onChanged: (_) {},
        ),
        DiamondPercentSlider(
          value: 70,
          nodes: 3,
          showLabels: true,
          activeColor: const Color(0xFF16A34A),
          indicatorColor: const Color(0xFF16A34A),
          onChanged: (_) {},
        ),
        const DiamondPercentSlider(
          value: 40,
          showLabels: true,
          onChanged: null,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/variants.png'),
    );
  });

  testWidgets('the same sliders in the dark theme', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(880, 400)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _canvas(
        <Widget>[
          DiamondPercentSlider(value: 25, onChanged: (_) {}),
          DiamondPercentSlider(
            value: 60,
            showLabels: true,
            onChanged: (_) {},
          ),
        ],
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/dark.png'),
    );
  });
}
