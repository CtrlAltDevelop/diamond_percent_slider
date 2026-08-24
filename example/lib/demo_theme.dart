import 'package:diamond_percent_slider/diamond_percent_slider.dart';
import 'package:material_ui/material_ui.dart';

/// The demo's theme, with a [DiamondSliderTheme] registered.
///
/// Everything the sliders in this app look like comes from here — none of them
/// pass colours of their own except where the demo is specifically showing a
/// per-instance override.
ThemeData buildDemoTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>[
      DiamondSliderTheme(
        activeColor: scheme.onSurface,
        inactiveColor: scheme.outlineVariant,
        thumbColor: scheme.surface,
        indicatorColor: scheme.onSurface,
        indicatorTextColor: scheme.surface,
        labelColor: scheme.onSurfaceVariant,
      ),
    ],
  );
}

/// A titled block, so each demo reads as its own thing.
class DemoSection extends StatelessWidget {
  const DemoSection({
    required this.title,
    required this.child,
    this.note,
    super.key,
  });

  /// What this section is showing.
  final String title;

  /// A line under the title, when the point needs saying.
  final String? note;

  /// The section's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
