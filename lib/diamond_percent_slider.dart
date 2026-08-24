/// An integer slider on a scale of diamonds, with a thumb that leans the way
/// it is dragged and a bubble showing the value while it moves.
///
/// ```dart
/// DiamondPercentSlider(
///   value: percent,
///   onChanged: (value) => setState(() => percent = value),
/// )
/// ```
///
/// The scale is decoration and the range is not: `nodes` diamonds are drawn
/// however wide `min` to `max` is, and each node's label is the value at that
/// point. Underneath it is the framework's [Slider], so keyboard control, the
/// drag gesture and semantics come free.
///
/// Material comes from the **`material_ui`** package rather than from
/// `package:flutter/material.dart`, so your app has to be on `material_ui`
/// too — its [ThemeData] and [ColorScheme] are not the framework's. Beyond
/// that the slider asks nothing of you: no assets, no localisations, no other
/// pub.dev dependency.
///
/// [DiamondSliderTheme] is a [ThemeExtension] covering colours, metrics and
/// the tilt. With none registered, the palette is derived from the ambient
/// [ColorScheme], so the slider is usable with no setup.
///
/// The four shapes it draws with — [DiamondSliderTrackShape],
/// [DiamondSliderThumbShape], [DiamondSliderTickMarkShape] and
/// [DiamondSliderValueIndicatorShape] — are exported too, for a plain [Slider]
/// that wants one of them through [SliderTheme].
library;

export 'src/diamond_percent_slider.dart';
export 'src/diamond_slider_shapes.dart';
export 'src/diamond_slider_theme.dart';
