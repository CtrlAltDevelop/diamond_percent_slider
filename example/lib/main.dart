// A runnable demo of every DiamondPercentSlider setting:
//
//   cd example && flutter run
import 'package:diamond_percent_slider/diamond_percent_slider.dart';
import 'package:material_ui/material_ui.dart';

import 'demo_theme.dart';

void main() => runApp(const DemoApp());

/// The demo, with light/dark and LTR/RTL toggles in the app bar.
class DemoApp extends StatefulWidget {
  /// Creates the demo app.
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  Brightness _brightness = Brightness.light;
  TextDirection _direction = TextDirection.ltr;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'diamond_percent_slider',
    theme: buildDemoTheme(_brightness),
    home: Directionality(
      textDirection: _direction,
      child: DemoPage(
        brightness: _brightness,
        direction: _direction,
        onToggleBrightness: () => setState(() {
          _brightness = _brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light;
        }),
        onToggleDirection: () => setState(() {
          _direction = _direction == TextDirection.ltr
              ? TextDirection.rtl
              : TextDirection.ltr;
        }),
      ),
    ),
  );
}

/// Every demo, one per section.
class DemoPage extends StatefulWidget {
  /// Creates the demo page.
  const DemoPage({
    required this.brightness,
    required this.direction,
    required this.onToggleBrightness,
    required this.onToggleDirection,
    super.key,
  });

  /// Which theme is showing, for the app bar's icon.
  final Brightness brightness;

  /// Which direction is showing, for the app bar's tooltip.
  final TextDirection direction;

  /// Flips the theme.
  final VoidCallback onToggleBrightness;

  /// Flips the text direction.
  final VoidCallback onToggleDirection;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  int _percent = 25;
  int _labelled = 60;
  int _leverage = 20;
  int _quarters = 50;
  int _tinted = 70;

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('diamond_percent_slider'),
        actions: <Widget>[
          IconButton(
            tooltip: widget.direction == TextDirection.ltr
                ? 'Switch to RTL'
                : 'Switch to LTR',
            onPressed: widget.onToggleDirection,
            icon: const Icon(Icons.swap_horiz),
          ),
          IconButton(
            tooltip: isDark ? 'Light theme' : 'Dark theme',
            onPressed: widget.onToggleBrightness,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            DemoSection(
              title: 'The default',
              note: '0 to 100, five nodes, no labels. Currently $_percent%.',
              child: DiamondPercentSlider(
                value: _percent,
                onChanged: (int value) => setState(() => _percent = value),
              ),
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: 'With the scale labelled',
              note: 'Each node reads the value at that point.',
              child: DiamondPercentSlider(
                value: _labelled,
                showLabels: true,
                onChanged: (int value) => setState(() => _labelled = value),
              ),
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: 'A leverage picker',
              note: 'Range 1–100, labelled with an x, its own bubble text.',
              child: DiamondPercentSlider(
                value: _leverage,
                min: 1,
                max: 100,
                showLabels: true,
                labelFormatter: (int value) => '${value}x',
                indicatorFormatter: (int value) => '${value}x leverage',
                onChanged: (int value) => setState(() => _leverage = value),
              ),
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: 'Coarse steps',
              note: 'Quarters only: step 25, so the thumb has five stops.',
              child: DiamondPercentSlider(
                value: _quarters,
                step: 25,
                showLabels: true,
                onChanged: (int value) => setState(() => _quarters = value),
              ),
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: 'Per-instance colours',
              note: 'Overriding the registered theme for this one slider.',
              child: DiamondPercentSlider(
                value: _tinted,
                nodes: 3,
                showLabels: true,
                activeColor: const Color(0xFF16A34A),
                indicatorColor: const Color(0xFF16A34A),
                onChanged: (int value) => setState(() => _tinted = value),
              ),
            ),
            const SizedBox(height: 16),
            const DemoSection(
              title: 'Disabled',
              note: 'A null onChanged dims the whole thing, labels included.',
              child: DiamondPercentSlider(
                value: 40,
                showLabels: true,
                onChanged: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
