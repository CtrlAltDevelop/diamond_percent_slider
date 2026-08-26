@Tags(<String>['golden'])
library;

import 'package:diamond_percent_slider/diamond_percent_slider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A slider on an opaque surface at a fixed size, so a golden captures the
/// painting and nothing else.
///
/// The scheme is pinned rather than taken from a seed: the shapes are what is
/// under test, and a Material palette tweak upstream should not repaint every
/// golden here.
Widget framed(Widget slider, {TextDirection direction = TextDirection.ltr}) {
  const ColorScheme scheme = ColorScheme.light(
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2937),
    outlineVariant: Color(0xFFD1D5DB),
    onSurfaceVariant: Color(0xFF6B7280),
    inverseSurface: Color(0xFF111827),
    onInverseSurface: Color(0xFFF9FAFB),
  );

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: Directionality(
      textDirection: direction,
      child: Material(
        color: scheme.surface,
        child: Center(
          child: SizedBox(
            width: 360,
            child: Padding(padding: const EdgeInsets.all(24), child: slider),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('default', (tester) async {
    await tester.pumpWidget(
      framed(DiamondPercentSlider(value: 50, onChanged: (_) {})),
    );

    await expectLater(
      find.byType(DiamondPercentSlider),
      matchesGoldenFile('goldens/default.png'),
    );
  });

  testWidgets('labelled', (tester) async {
    await tester.pumpWidget(
      framed(
        DiamondPercentSlider(value: 75, showLabels: true, onChanged: (_) {}),
      ),
    );

    await expectLater(
      find.byType(DiamondPercentSlider),
      matchesGoldenFile('goldens/labelled.png'),
    );
  });

  testWidgets('disabled', (tester) async {
    await tester.pumpWidget(
      framed(
        const DiamondPercentSlider(
          value: 40,
          showLabels: true,
          onChanged: null,
        ),
      ),
    );

    await expectLater(
      find.byType(DiamondPercentSlider),
      matchesGoldenFile('goldens/disabled.png'),
    );
  });

  testWidgets('rtl', (tester) async {
    await tester.pumpWidget(
      framed(
        DiamondPercentSlider(value: 25, showLabels: true, onChanged: (_) {}),
        direction: TextDirection.rtl,
      ),
    );

    await expectLater(
      find.byType(DiamondPercentSlider),
      matchesGoldenFile('goldens/rtl.png'),
    );
  });

  testWidgets('coarse nodes', (tester) async {
    await tester.pumpWidget(
      framed(
        DiamondPercentSlider(
          value: 60,
          nodes: 3,
          step: 20,
          showLabels: true,
          onChanged: (_) {},
        ),
      ),
    );

    await expectLater(
      find.byType(DiamondPercentSlider),
      matchesGoldenFile('goldens/coarse-nodes.png'),
    );
  });

  // The value indicator is painted into the Slider's overlay layer, which sits
  // outside this subtree, so it is not in this golden — the tilt is.
  testWidgets('mid-tilt', (tester) async {
    int value = 50;
    await tester.pumpWidget(
      framed(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              DiamondPercentSlider(
                value: value,
                onChanged: (int next) => setState(() => value = next),
              ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    // Long enough for the tilt to have settled, so the golden is a resting
    // frame rather than a race.
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(DiamondPercentSlider),
      matchesGoldenFile('goldens/tilted.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
