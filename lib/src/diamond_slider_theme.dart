import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Colours, metrics and motion for `DiamondPercentSlider` and the shapes it
/// draws with.
///
/// Register one so every slider in the app is styled in one place and follows
/// the light and dark themes:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [
///       DiamondSliderTheme(
///         activeColor: scheme.onSurface,
///         inactiveColor: scheme.outlineVariant,
///         indicatorColor: scheme.inverseSurface,
///       ),
///     ],
///   ),
/// );
/// ```
///
/// Every colour is optional: [resolve] fills the null ones from the ambient
/// [ColorScheme], so a slider is usable with no setup at all. The metrics have
/// constant defaults, and the widget's own parameters win over both.
@immutable
class DiamondSliderTheme extends ThemeExtension<DiamondSliderTheme> {
  /// Creates a theme. Colours left null are derived from the ambient scheme
  /// when the slider [resolve]s this theme.
  const DiamondSliderTheme({
    this.activeColor,
    this.inactiveColor,
    this.disabledColor,
    this.thumbColor,
    this.thumbBorderColor,
    this.indicatorColor,
    this.indicatorTextColor,
    this.labelColor,
    this.overlayColor,
    this.thumbBorderWidth = 1.5,
    this.thumbSize = 14,
    this.nodeSize = 8,
    this.trackThickness = 2,
    this.overlayRadius = 14,
    this.indicatorRadius = 6,
    this.indicatorGap = 8,
    this.indicatorPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 4,
    ),
    this.indicatorMinWidth = 30,
    this.labelSpacing = 6,
    this.labelStyle,
    this.indicatorTextStyle,
    this.disabledOpacity = 0.38,
    this.tiltAngle = 0.3,
    this.tiltDuration = const Duration(milliseconds: 160),
    this.tiltCurve = Curves.easeOut,
  }) : assert(thumbSize > 0, 'the thumb needs a size'),
       assert(nodeSize > 0, 'the nodes need a size'),
       assert(trackThickness > 0, 'the track needs a thickness'),
       assert(overlayRadius >= 0, 'a negative overlay radius makes no sense'),
       assert(
         disabledOpacity >= 0 && disabledOpacity <= 1,
         'disabledOpacity is a fraction',
       );

  /// A theme derived entirely from [scheme], used when none is registered.
  factory DiamondSliderTheme.fromScheme(ColorScheme scheme) =>
      const DiamondSliderTheme().resolve(scheme);

  /// The track and nodes behind the thumb, and the filled part of the line.
  final Color? activeColor;

  /// The track and nodes ahead of the thumb.
  final Color? inactiveColor;

  /// What everything fades towards when the slider is disabled.
  ///
  /// Defaults to [activeColor] at [disabledOpacity].
  final Color? disabledColor;

  /// The thumb's fill.
  final Color? thumbColor;

  /// The thumb's outline. Width `0` drops it.
  final Color? thumbBorderColor;

  /// The value bubble's fill.
  final Color? indicatorColor;

  /// The value bubble's text, when [indicatorTextStyle] does not set a colour.
  final Color? indicatorTextColor;

  /// The scale labels' colour, when [labelStyle] does not set one.
  final Color? labelColor;

  /// The press-and-drag halo around the thumb.
  final Color? overlayColor;

  /// The width of the thumb's outline. `0` drops it.
  final double thumbBorderWidth;

  /// The thumb diamond's width and height.
  final double thumbSize;

  /// Each scale node diamond's width and height.
  final double nodeSize;

  /// The thickness of the line between nodes.
  final double trackThickness;

  /// The radius of the halo around a pressed thumb. Also sets how far the
  /// track is inset from the slider's edges, which is what the scale labels
  /// are aligned against.
  final double overlayRadius;

  /// The value bubble's corner radius.
  final double indicatorRadius;

  /// The gap between the thumb and the bubble above it.
  final double indicatorGap;

  /// The inset between the bubble's text and its edges.
  final EdgeInsets indicatorPadding;

  /// The narrowest the bubble may be, however short its text.
  final double indicatorMinWidth;

  /// The gap between the track and the scale labels under it.
  final double labelSpacing;

  /// The scale labels' text style. Merged over `bodySmall`.
  final TextStyle? labelStyle;

  /// The value bubble's text style. Merged over `labelSmall`.
  final TextStyle? indicatorTextStyle;

  /// How far colours fade when the slider is disabled.
  final double disabledOpacity;

  /// How far the thumb tilts while being dragged, in radians.
  ///
  /// The tilt follows the drag: rightwards leans one way, leftwards the other,
  /// and letting go returns it to level. `0` holds it level throughout.
  final double tiltAngle;

  /// How long the thumb takes to reach a new tilt.
  final Duration tiltDuration;

  /// The curve the tilt animates on.
  final Curve tiltCurve;

  /// This theme with every null colour filled in from [scheme].
  ///
  /// Called by the slider, so a host rarely needs it — but a host drawing with
  /// the shapes directly does, since they take non-null colours.
  DiamondSliderTheme resolve(ColorScheme scheme) {
    final Color active = activeColor ?? scheme.onSurface;
    return copyWith(
      activeColor: active,
      inactiveColor: inactiveColor ?? scheme.outlineVariant,
      disabledColor:
          disabledColor ?? active.withValues(alpha: disabledOpacity),
      thumbColor: thumbColor ?? scheme.surface,
      thumbBorderColor: thumbBorderColor ?? active,
      indicatorColor: indicatorColor ?? scheme.inverseSurface,
      indicatorTextColor: indicatorTextColor ?? scheme.onInverseSurface,
      labelColor: labelColor ?? scheme.onSurfaceVariant,
      overlayColor: overlayColor ?? active.withValues(alpha: 0.08),
    );
  }

  /// The registered theme, or one derived from the ambient [ColorScheme].
  ///
  /// Always fully resolved, so every colour on the result is non-null.
  static DiamondSliderTheme of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return (theme.extension<DiamondSliderTheme>() ??
            const DiamondSliderTheme())
        .resolve(theme.colorScheme);
  }

  @override
  DiamondSliderTheme copyWith({
    Color? activeColor,
    Color? inactiveColor,
    Color? disabledColor,
    Color? thumbColor,
    Color? thumbBorderColor,
    Color? indicatorColor,
    Color? indicatorTextColor,
    Color? labelColor,
    Color? overlayColor,
    double? thumbBorderWidth,
    double? thumbSize,
    double? nodeSize,
    double? trackThickness,
    double? overlayRadius,
    double? indicatorRadius,
    double? indicatorGap,
    EdgeInsets? indicatorPadding,
    double? indicatorMinWidth,
    double? labelSpacing,
    TextStyle? labelStyle,
    TextStyle? indicatorTextStyle,
    double? disabledOpacity,
    double? tiltAngle,
    Duration? tiltDuration,
    Curve? tiltCurve,
  }) => DiamondSliderTheme(
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    disabledColor: disabledColor ?? this.disabledColor,
    thumbColor: thumbColor ?? this.thumbColor,
    thumbBorderColor: thumbBorderColor ?? this.thumbBorderColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorTextColor: indicatorTextColor ?? this.indicatorTextColor,
    labelColor: labelColor ?? this.labelColor,
    overlayColor: overlayColor ?? this.overlayColor,
    thumbBorderWidth: thumbBorderWidth ?? this.thumbBorderWidth,
    thumbSize: thumbSize ?? this.thumbSize,
    nodeSize: nodeSize ?? this.nodeSize,
    trackThickness: trackThickness ?? this.trackThickness,
    overlayRadius: overlayRadius ?? this.overlayRadius,
    indicatorRadius: indicatorRadius ?? this.indicatorRadius,
    indicatorGap: indicatorGap ?? this.indicatorGap,
    indicatorPadding: indicatorPadding ?? this.indicatorPadding,
    indicatorMinWidth: indicatorMinWidth ?? this.indicatorMinWidth,
    labelSpacing: labelSpacing ?? this.labelSpacing,
    labelStyle: labelStyle ?? this.labelStyle,
    indicatorTextStyle: indicatorTextStyle ?? this.indicatorTextStyle,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    tiltAngle: tiltAngle ?? this.tiltAngle,
    tiltDuration: tiltDuration ?? this.tiltDuration,
    tiltCurve: tiltCurve ?? this.tiltCurve,
  );

  @override
  DiamondSliderTheme lerp(DiamondSliderTheme? other, double t) {
    if (other == null) return this;
    return DiamondSliderTheme(
      activeColor: Color.lerp(activeColor, other.activeColor, t),
      inactiveColor: Color.lerp(inactiveColor, other.inactiveColor, t),
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t),
      thumbColor: Color.lerp(thumbColor, other.thumbColor, t),
      thumbBorderColor: Color.lerp(
        thumbBorderColor,
        other.thumbBorderColor,
        t,
      ),
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t),
      indicatorTextColor: Color.lerp(
        indicatorTextColor,
        other.indicatorTextColor,
        t,
      ),
      labelColor: Color.lerp(labelColor, other.labelColor, t),
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t),
      thumbBorderWidth:
          lerpDouble(thumbBorderWidth, other.thumbBorderWidth, t) ??
          thumbBorderWidth,
      thumbSize: lerpDouble(thumbSize, other.thumbSize, t) ?? thumbSize,
      nodeSize: lerpDouble(nodeSize, other.nodeSize, t) ?? nodeSize,
      trackThickness:
          lerpDouble(trackThickness, other.trackThickness, t) ??
          trackThickness,
      overlayRadius:
          lerpDouble(overlayRadius, other.overlayRadius, t) ?? overlayRadius,
      indicatorRadius:
          lerpDouble(indicatorRadius, other.indicatorRadius, t) ??
          indicatorRadius,
      indicatorGap:
          lerpDouble(indicatorGap, other.indicatorGap, t) ?? indicatorGap,
      indicatorPadding:
          EdgeInsets.lerp(indicatorPadding, other.indicatorPadding, t) ??
          indicatorPadding,
      indicatorMinWidth:
          lerpDouble(indicatorMinWidth, other.indicatorMinWidth, t) ??
          indicatorMinWidth,
      labelSpacing:
          lerpDouble(labelSpacing, other.labelSpacing, t) ?? labelSpacing,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      indicatorTextStyle: TextStyle.lerp(
        indicatorTextStyle,
        other.indicatorTextStyle,
        t,
      ),
      disabledOpacity:
          lerpDouble(disabledOpacity, other.disabledOpacity, t) ??
          disabledOpacity,
      tiltAngle: lerpDouble(tiltAngle, other.tiltAngle, t) ?? tiltAngle,
      // Durations and curves jump at the halfway point: interpolating them
      // would make an in-flight animation stutter rather than settle.
      tiltDuration: t < 0.5 ? tiltDuration : other.tiltDuration,
      tiltCurve: t < 0.5 ? tiltCurve : other.tiltCurve,
    );
  }

  @override
  Object get type => DiamondSliderTheme;
}
