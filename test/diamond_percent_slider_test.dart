import 'package:diamond_percent_slider/diamond_percent_slider.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The slider under a plain app, at a known width so drag maths is stable.
Widget host(
  Widget slider, {
  DiamondSliderTheme? extension,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) => MaterialApp(
  theme: ThemeData(extensions: <ThemeExtension<dynamic>>[?extension]),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Center(child: SizedBox(width: 400, child: slider)),
      ),
    ),
  ),
);

/// The haptic ticks the slider asked the platform for, in order.
List<String> recordHaptics(WidgetTester tester) {
  final List<String> calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String? ?? 'default');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// The `SliderThemeData` the widget built, which is where the shapes live.
SliderThemeData themeOf(WidgetTester tester) =>
    tester.widget<SliderTheme>(find.byType(SliderTheme)).data;

DiamondSliderTrackShape trackOf(WidgetTester tester) =>
    themeOf(tester).trackShape! as DiamondSliderTrackShape;

DiamondSliderThumbShape thumbOf(WidgetTester tester) =>
    themeOf(tester).thumbShape! as DiamondSliderThumbShape;

/// What a screen reader would read out for the slider.
///
/// The node carrying it is below the one `getSemantics` lands on — the Slider's
/// value-indicator overlay sits in between — so walk down to the first node
/// with a value.
String announcedValue(WidgetTester tester) {
  String? valueOf(SemanticsNode node) {
    final String value = node.getSemanticsData().value;
    if (value.isNotEmpty) return value;
    String? found;
    node.visitChildren((SemanticsNode child) {
      found ??= valueOf(child);
      return found == null;
    });
    return found;
  }

  return valueOf(tester.getSemantics(find.byType(Slider))) ?? '';
}

void main() {
  group('values', () {
    testWidgets('reports the value to a screen reader', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 40, onChanged: (_) {})),
      );

      expect(announcedValue(tester), '40%');
      handle.dispose();
    });

    testWidgets('a drag reports whole steps, snapped', (tester) async {
      final List<int> reported = <int>[];
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 0, onChanged: reported.add)),
      );

      final Offset start = tester.getCenter(find.byType(Slider));
      await tester.dragFrom(start, const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(
        reported.every((int v) => v >= 0 && v <= 100),
        isTrue,
        reason: 'never outside the range',
      );
      expect(reported.last, greaterThan(50), reason: 'dragged rightwards');
    });

    testWidgets('step keeps every reported value on the grid', (tester) async {
      final List<int> reported = <int>[];
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, step: 25, onChanged: reported.add),
        ),
      );

      await tester.dragFrom(
        tester.getCenter(find.byType(Slider)),
        const Offset(-160, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.every((int v) => v % 25 == 0), isTrue);
    });

    testWidgets('divisions land on integers, not between them', (tester) async {
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 0, onChanged: (_) {})),
      );

      // 100 divisions over 0–100, not 101: with one too many, no drag stop
      // lands on a whole number.
      expect(tester.widget<Slider>(find.byType(Slider)).divisions, 100);
    });

    testWidgets('an out-of-range value is clamped for display', (tester) async {
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 500, max: 100, onChanged: (_) {})),
      );

      expect(tester.widget<Slider>(find.byType(Slider)).value, 100.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a non-zero min shifts the whole scale', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 5,
            min: 5,
            max: 100,
            step: 5,
            onChanged: (_) {},
          ),
        ),
      );

      final Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 5.0);
      expect(slider.max, 100.0);
      expect(slider.divisions, 19);
    });
  });

  group('the scale', () {
    testWidgets('no labels unless asked for', (tester) async {
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 50, onChanged: (_) {})),
      );

      expect(find.text('50%'), findsNothing);
    });

    testWidgets('labels the value at each node', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, showLabels: true, onChanged: (_) {}),
        ),
      );

      for (final String label in <String>['0%', '25%', '50%', '75%', '100%']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('spreads the labels over a non-zero min', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 5,
            min: 5,
            max: 100,
            step: 5,
            showLabels: true,
            labelFormatter: (int value) => '${value}x',
            onChanged: (_) {},
          ),
        ),
      );

      // The ends are exact; the ones between are rounded off the range.
      expect(find.text('5x'), findsOneWidget);
      expect(find.text('100x'), findsOneWidget);
      expect(find.text('29x'), findsOneWidget);
      expect(find.text('53x'), findsOneWidget);
      expect(find.text('76x'), findsOneWidget);
    });

    testWidgets('honours the node count', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 0,
            nodes: 3,
            showLabels: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('25%'), findsNothing);
      expect(trackOf(tester).nodes, 3);
    });

    testWidgets('the labels line up in ascending order, evenly', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 0, showLabels: true, onChanged: (_) {}),
        ),
      );

      final List<double> centres = <double>[
        for (final String label in <String>['0%', '25%', '50%', '75%', '100%'])
          tester.getCenter(find.text(label)).dx,
      ];

      for (int i = 1; i < centres.length; i++) {
        expect(centres[i], greaterThan(centres[i - 1]));
      }
      // Evenly spaced, within a pixel of rounding.
      final double gap = centres[1] - centres[0];
      for (int i = 1; i < centres.length; i++) {
        expect(centres[i] - centres[i - 1], closeTo(gap, 1));
      }
    });

    testWidgets('the middle label sits on the slider centre', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 0, showLabels: true, onChanged: (_) {}),
        ),
      );

      expect(
        tester.getCenter(find.text('50%')).dx,
        closeTo(tester.getCenter(find.byType(Slider)).dx, 1),
      );
    });

    testWidgets('under RTL the low values sit on the right', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 0, showLabels: true, onChanged: (_) {}),
          direction: TextDirection.rtl,
        ),
      );

      expect(
        tester.getCenter(find.text('0%')).dx,
        greaterThan(tester.getCenter(find.text('100%')).dx),
      );
    });

    testWidgets('the labels are hidden from screen readers', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, showLabels: true, onChanged: (_) {}),
        ),
      );

      expect(
        find.ancestor(
          of: find.text('25%'),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('formatting', () {
    testWidgets('labelFormatter drives labels, bubble and semantics', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 12,
            showLabels: true,
            labelFormatter: (int value) => '$value dB',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('0 dB'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).label, '12 dB');
      expect(announcedValue(tester), '12 dB');
      handle.dispose();
    });

    testWidgets('indicatorFormatter overrides only the bubble', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 12,
            showLabels: true,
            labelFormatter: (int value) => '$value',
            indicatorFormatter: (int value) => '$value of 100',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget, reason: 'the scale is unchanged');
      expect(tester.widget<Slider>(find.byType(Slider)).label, '12 of 100');
    });

    testWidgets('semanticFormatter overrides only the announcement', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 30,
            semanticFormatter: (int value) => '$value per cent of balance',
            onChanged: (_) {},
          ),
        ),
      );

      expect(announcedValue(tester), '30 per cent of balance');
      expect(tester.widget<Slider>(find.byType(Slider)).label, '30%');
      handle.dispose();
    });
  });

  group('the tilt', () {
    testWidgets('starts level', (tester) async {
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 50, onChanged: (_) {})),
      );

      expect(thumbOf(tester).angle, 0);
    });

    testWidgets('leans into a rightward drag and returns level', (
      tester,
    ) async {
      int value = 50;
      await tester.pumpWidget(
        host(
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
      // The frame the drag lands in starts the animation at its begin value;
      // it advances from the next frame on.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(thumbOf(tester).angle, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(thumbOf(tester).angle, 0);
    });

    testWidgets('leans the other way going left', (tester) async {
      int value = 50;
      await tester.pumpWidget(
        host(
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
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(thumbOf(tester).angle, lessThan(0));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('under RTL it still leans the way the finger goes', (
      tester,
    ) async {
      int value = 50;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                DiamondPercentSlider(
                  value: value,
                  onChanged: (int next) => setState(() => value = next),
                ),
          ),
          direction: TextDirection.rtl,
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Slider)),
      );
      // Rightwards under RTL lowers the value, but the lean follows the
      // finger, so it matches the LTR rightward drag rather than opposing it.
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(value, lessThan(50));
      expect(thumbOf(tester).angle, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'a tilt frame repaints the thumb without rebuilding the Slider',
      (tester) async {
        await tester.pumpWidget(
          host(DiamondPercentSlider(value: 50, onChanged: (_) {})),
        );

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byType(Slider)),
        );
        await gesture.moveBy(const Offset(40, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        final Slider first = tester.widget<Slider>(find.byType(Slider));
        final double firstAngle = thumbOf(tester).angle;

        await tester.pump(const Duration(milliseconds: 40));
        final Slider second = tester.widget<Slider>(find.byType(Slider));

        expect(
          thumbOf(tester).angle,
          isNot(firstAngle),
          reason: 'the tilt was still animating between those frames',
        );
        expect(
          identical(first, second),
          isTrue,
          reason: 'the Slider is hoisted out of the tilt animation',
        );

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('tiltAngle 0 holds the thumb level throughout', (tester) async {
      int value = 50;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                DiamondPercentSlider(
                  value: value,
                  onChanged: (int next) => setState(() => value = next),
                ),
          ),
          extension: const DiamondSliderTheme(tiltAngle: 0),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Slider)),
      );
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(thumbOf(tester).angle, 0);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('being disabled', () {
    testWidgets('a null onChanged stops input', (tester) async {
      await tester.pumpWidget(
        host(const DiamondPercentSlider(value: 50, onChanged: null)),
      );

      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    });

    testWidgets('enabled: false stops input with a callback in place', (
      tester,
    ) async {
      final List<int> reported = <int>[];
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 50,
            enabled: false,
            onChanged: reported.add,
          ),
        ),
      );

      await tester.dragFrom(
        tester.getCenter(find.byType(Slider)),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
    });

    testWidgets('the track dims', (tester) async {
      await tester.pumpWidget(
        host(const DiamondPercentSlider(value: 50, onChanged: null)),
      );
      final Color disabled = trackOf(tester).activeColor;

      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 50, onChanged: (_) {})),
      );
      final Color enabled = trackOf(tester).activeColor;

      expect(disabled, isNot(enabled));
      expect(disabled.a, lessThan(enabled.a));
    });
  });

  group('haptics', () {
    testWidgets('ticks once per step change', (tester) async {
      final List<String> haptics = recordHaptics(tester);
      int value = 0;
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: value,
            step: 25,
            onChanged: (int v) => value = v,
          ),
        ),
      );

      final Offset centre = tester.getCenter(find.byType(Slider));
      final TestGesture gesture = await tester.startGesture(centre);
      await gesture.moveBy(const Offset(4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(value, 50, reason: 'the tap alone moved it to the centre');
      expect(haptics, <String>['HapticFeedbackType.selectionClick']);
    });

    testWidgets('says nothing when the value does not change', (tester) async {
      final List<String> haptics = recordHaptics(tester);
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 50, step: 50, onChanged: (_) {})),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Slider)),
      );
      await gesture.moveBy(const Offset(2, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(haptics, isEmpty);
    });

    testWidgets('enableFeedback: false stays silent through a drag', (
      tester,
    ) async {
      final List<String> haptics = recordHaptics(tester);
      final List<int> reported = <int>[];
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 0,
            enableFeedback: false,
            onChanged: reported.add,
          ),
        ),
      );

      await tester.dragFrom(
        tester.getCenter(find.byType(Slider)),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty, reason: 'the drag did move the value');
      expect(haptics, isEmpty);
    });
  });

  group('pass-throughs', () {
    testWidgets('mouseCursor reaches the Slider', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 50,
            mouseCursor: SystemMouseCursors.grab,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.widget<Slider>(find.byType(Slider)).mouseCursor,
        SystemMouseCursors.grab,
      );
    });

    testWidgets('allowedInteraction reaches the Slider', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 50,
            allowedInteraction: SliderInteraction.slideOnly,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.widget<Slider>(find.byType(Slider)).allowedInteraction,
        SliderInteraction.slideOnly,
      );
    });

    testWidgets('slideOnly ignores a tap away from the thumb', (tester) async {
      final List<int> reported = <int>[];
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 0,
            allowedInteraction: SliderInteraction.slideOnly,
            onChanged: reported.add,
          ),
        ),
      );

      await tester.tapAt(tester.getCenter(find.byType(Slider)));
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
    });

    testWidgets('padding reaches the Slider and moves the labels with it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 0, showLabels: true, onChanged: (_) {}),
        ),
      );
      final double bare = tester.getCenter(find.text('0%')).dx;

      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 0,
            showLabels: true,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.widget<Slider>(find.byType(Slider)).padding,
        const EdgeInsets.symmetric(horizontal: 40),
      );
      expect(
        tester.getCenter(find.text('0%')).dx,
        moreOrLessEquals(bare + 40, epsilon: 0.5),
        reason: 'the first label follows the track it labels',
      );
    });

    testWidgets('directional padding is mirrored under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 0,
            showLabels: true,
            padding: const EdgeInsetsDirectional.only(start: 40),
            onChanged: (_) {},
          ),
          direction: TextDirection.rtl,
        ),
      );
      final double start = tester.getCenter(find.text('0%')).dx;
      final double end = tester.getCenter(find.text('100%')).dx;

      expect(
        start,
        greaterThan(end),
        reason: 'under RTL the scale starts on the right',
      );
      expect(
        start,
        lessThan(tester.getCenter(find.byType(Slider)).dx + 200 - 40),
        reason: 'the start padding took 40 off the right-hand edge',
      );
    });
  });

  group('the labels row', () {
    /// The stack the scale labels are positioned in.
    final Finder labelRow = find.ancestor(
      of: find.text('0%'),
      matching: find.byType(Stack),
    );

    testWidgets('is measured, so it grows with the text scale', (tester) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, showLabels: true, onChanged: (_) {}),
        ),
      );
      final double bare = tester.getSize(find.text('0%')).height;
      final double bareRow = tester.getSize(labelRow).height;

      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, showLabels: true, onChanged: (_) {}),
          textScale: 2,
        ),
      );
      final double scaled = tester.getSize(find.text('0%')).height;
      final double scaledRow = tester.getSize(labelRow).height;

      expect(scaled, greaterThan(bare), reason: 'the text itself grew');
      expect(bareRow, moreOrLessEquals(bare, epsilon: 0.5));
      expect(
        scaledRow,
        moreOrLessEquals(scaled, epsilon: 0.5),
        reason: 'the row is as tall as its tallest label, not a fixed guess',
      );
    });
  });

  group('theming', () {
    testWidgets('with nothing registered the colours come from the scheme', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 50, onChanged: (_) {})),
      );

      final ColorScheme scheme = ThemeData().colorScheme;
      expect(trackOf(tester).activeColor, scheme.onSurface);
      expect(trackOf(tester).inactiveColor, scheme.outlineVariant);
    });

    testWidgets('a registered extension reaches the shapes', (tester) async {
      const Color active = Color(0xFF112233);
      const Color inactive = Color(0xFF445566);

      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, onChanged: (_) {}),
          extension: const DiamondSliderTheme(
            activeColor: active,
            inactiveColor: inactive,
            nodeSize: 12,
            trackThickness: 3,
          ),
        ),
      );

      expect(trackOf(tester).activeColor, active);
      expect(trackOf(tester).inactiveColor, inactive);
      expect(trackOf(tester).nodeSize, 12);
      expect(trackOf(tester).thickness, 3);
    });

    testWidgets('a per-instance colour beats the extension', (tester) async {
      const Color instance = Color(0xFFAABBCC);

      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 50,
            activeColor: instance,
            onChanged: (_) {},
          ),
          extension: const DiamondSliderTheme(activeColor: Color(0xFF000000)),
        ),
      );

      expect(trackOf(tester).activeColor, instance);
    });

    testWidgets('the extension thumb border colour reaches the thumb', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, onChanged: (_) {}),
          extension: const DiamondSliderTheme(
            thumbBorderColor: Color(0xFFAB1234),
          ),
        ),
      );

      expect(thumbOf(tester).borderColor, const Color(0xFFAB1234));
    });

    testWidgets('a per-instance thumb border colour beats the extension', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 50,
            onChanged: (_) {},
            thumbBorderColor: const Color(0xFF00FF00),
          ),
          extension: const DiamondSliderTheme(
            thumbBorderColor: Color(0xFFAB1234),
          ),
        ),
      );

      expect(thumbOf(tester).borderColor, const Color(0xFF00FF00));
    });

    testWidgets(
      'with no outline colour set the outline follows the active one',
      (tester) async {
        const Color tint = Color(0xFF16A34A);
        await tester.pumpWidget(
          host(
            DiamondPercentSlider(
              value: 50,
              activeColor: tint,
              onChanged: (_) {},
            ),
            // The extension names an active colour but no outline colour, so the
            // per-instance tint has to reach the outline as well as the track.
            extension: const DiamondSliderTheme(activeColor: Color(0xFF111111)),
          ),
        );

        expect(trackOf(tester).activeColor, tint);
        expect(thumbOf(tester).borderColor, tint);
      },
    );

    testWidgets('an extension outline colour survives a per-instance tint', (
      tester,
    ) async {
      const Color border = Color(0xFFAB1234);
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(
            value: 50,
            activeColor: const Color(0xFF16A34A),
            onChanged: (_) {},
          ),
          extension: const DiamondSliderTheme(thumbBorderColor: border),
        ),
      );

      expect(thumbOf(tester).borderColor, border);
    });

    testWidgets('a disabled thumb dims its outline rather than keeping it', (
      tester,
    ) async {
      const Color border = Color(0xFFAB1234);
      await tester.pumpWidget(
        host(
          const DiamondPercentSlider(value: 50, onChanged: null),
          extension: const DiamondSliderTheme(thumbBorderColor: border),
        ),
      );

      expect(thumbOf(tester).borderColor, isNot(border));
    });

    testWidgets('the track rect keeps its height, so the nodes have room', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DiamondPercentSlider(value: 50, onChanged: (_) {}),
          extension: const DiamondSliderTheme(nodeSize: 10),
        ),
      );

      // BaseSliderTrackShape flattens the rect to nothing when both track
      // colours are transparent, which would leave the nodes nowhere to sit.
      expect(themeOf(tester).trackHeight, 10);
      expect(themeOf(tester).activeTrackColor, isNot(const Color(0x00000000)));
    });

    testWidgets('no tick marks, whatever the division count', (tester) async {
      await tester.pumpWidget(
        host(DiamondPercentSlider(value: 50, onChanged: (_) {})),
      );

      expect(themeOf(tester).tickMarkShape, SliderTickMarkShape.noTickMark);
    });
  });

  group('DiamondSliderTheme', () {
    test('resolve fills every colour from the scheme', () {
      final ColorScheme scheme = ThemeData().colorScheme;
      final DiamondSliderTheme resolved = const DiamondSliderTheme().resolve(
        scheme,
      );

      expect(resolved.activeColor, isNotNull);
      expect(resolved.inactiveColor, isNotNull);
      expect(resolved.disabledColor, isNotNull);
      expect(resolved.thumbColor, isNotNull);
      expect(resolved.thumbBorderColor, isNotNull);
      expect(resolved.indicatorColor, isNotNull);
      expect(resolved.indicatorTextColor, isNotNull);
      expect(resolved.labelColor, isNotNull);
      expect(resolved.overlayColor, isNotNull);
    });

    test('resolve leaves a colour the host set alone', () {
      const Color mine = Color(0xFF010203);
      expect(
        const DiamondSliderTheme(activeColor: mine)
            .resolve(ThemeData().colorScheme)
            .activeColor,
        mine,
      );
    });

    test('fromScheme is a fully resolved theme', () {
      expect(
        DiamondSliderTheme.fromScheme(ThemeData().colorScheme).activeColor,
        isNotNull,
      );
    });

    test('copyWith replaces only what it is given', () {
      const DiamondSliderTheme base = DiamondSliderTheme(
        activeColor: Color(0xFF000000),
        nodeSize: 9,
      );
      final DiamondSliderTheme copy = base.copyWith(nodeSize: 11);

      expect(copy.nodeSize, 11);
      expect(copy.activeColor, base.activeColor);
    });

    test('lerp moves colours and metrics', () {
      const DiamondSliderTheme a = DiamondSliderTheme(
        activeColor: Color(0xFF000000),
        nodeSize: 8,
        tiltAngle: 0,
      );
      const DiamondSliderTheme b = DiamondSliderTheme(
        activeColor: Color(0xFFFFFFFF),
        nodeSize: 16,
        tiltAngle: 1,
      );

      final DiamondSliderTheme mid = a.lerp(b, 0.5);
      expect(mid.nodeSize, 12);
      expect(mid.tiltAngle, 0.5);
      expect(mid.activeColor, isNot(a.activeColor));
      expect(mid.activeColor, isNot(b.activeColor));
    });

    test('lerp against null keeps this theme', () {
      const DiamondSliderTheme theme = DiamondSliderTheme(nodeSize: 8);
      expect(theme.lerp(null, 0.5).nodeSize, 8);
    });

    test('type identifies the extension', () {
      expect(const DiamondSliderTheme().type, DiamondSliderTheme);
    });
  });

  group('valueAtNode', () {
    test('the ends are exact', () {
      expect(
        DiamondPercentSlider.valueAtNode(index: 0, nodes: 5, min: 5, max: 100),
        5,
      );
      expect(
        DiamondPercentSlider.valueAtNode(index: 4, nodes: 5, min: 5, max: 100),
        100,
      );
    });

    test('the ones between are spread across the range', () {
      expect(
        <int>[
          for (int i = 0; i < 5; i++)
            DiamondPercentSlider.valueAtNode(
              index: i,
              nodes: 5,
              min: 0,
              max: 100,
            ),
        ],
        <int>[0, 25, 50, 75, 100],
      );
    });

    test('two nodes are just the ends', () {
      expect(
        DiamondPercentSlider.valueAtNode(index: 1, nodes: 2, min: 0, max: 7),
        7,
      );
    });
  });

  group('what it refuses to build', () {
    test('a range with no width', () {
      expect(
        () => DiamondPercentSlider(value: 0, max: 0, onChanged: (_) {}),
        throwsAssertionError,
      );
    });

    test('a step that does not divide the range', () {
      expect(
        () => DiamondPercentSlider(
          value: 0,
          max: 100,
          step: 3,
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('a scale with fewer than two nodes', () {
      expect(
        () => DiamondPercentSlider(value: 0, nodes: 1, onChanged: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => DiamondSliderTrackShape(
          nodes: 1,
          activeColor: const Color(0xFF000000),
          inactiveColor: const Color(0xFF000000),
        ),
        throwsAssertionError,
      );
    });
  });
}
