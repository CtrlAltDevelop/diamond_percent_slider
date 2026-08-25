import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A diamond centred on ([cx], [cy]), [size] across.
Path _diamond(double cx, double cy, double size) {
  final double half = size / 2;
  return Path()
    ..moveTo(cx, cy - half)
    ..lineTo(cx + half, cy)
    ..lineTo(cx, cy + half)
    ..lineTo(cx - half, cy)
    ..close();
}

/// A slider track drawn as a row of diamonds joined by a line, filled up to
/// the thumb.
///
/// The nodes are placed against the track's real geometry rather than guessed
/// at, so they line up with the thumb exactly: node *i* of *n* sits where the
/// thumb sits at that fraction of the range. That holds under any thumb size,
/// overlay radius or text direction.
///
/// Usable on a plain [Slider] through [SliderTheme] — nothing here depends on
/// `DiamondPercentSlider`:
///
/// ```dart
/// SliderTheme(
///   data: SliderTheme.of(context).copyWith(
///     trackShape: const DiamondSliderTrackShape(
///       nodes: 5,
///       activeColor: Color(0xFF1F2937),
///       inactiveColor: Color(0xFFD1D5DB),
///     ),
///   ),
///   child: Slider(value: v, onChanged: onChanged),
/// )
/// ```
class DiamondSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  /// Creates a diamond scale of [nodes] nodes.
  ///
  /// [nodes] must be at least 2 — the two ends. Fewer would leave nothing to
  /// join.
  const DiamondSliderTrackShape({
    required this.nodes,
    required this.activeColor,
    required this.inactiveColor,
    this.nodeSize = 8,
    this.thickness = 2,
  }) : assert(nodes >= 2, 'a scale needs at least its two ends'),
       assert(nodeSize > 0),
       assert(thickness > 0);

  /// How many diamonds sit on the track, ends included.
  final int nodes;

  /// The colour of the line and nodes up to the thumb.
  final Color activeColor;

  /// The colour of the line and nodes past the thumb.
  final Color inactiveColor;

  /// Each diamond's width and height.
  final double nodeSize;

  /// The thickness of the line joining the diamonds.
  final double thickness;

  /// Rounding slack, so a node sitting exactly under the thumb counts as
  /// reached rather than falling on the wrong side of a floating-point
  /// comparison.
  static const double _epsilon = 0.5;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect track = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (track.width <= 0) return;

    final Canvas canvas = context.canvas;
    final double cy = track.center.dy;

    // Everything between the near edge and the thumb is filled. Which edge is
    // near depends on the text direction, and the framework has already put
    // the thumb on the correct side for it.
    final double activeStart = textDirection == TextDirection.ltr
        ? track.left
        : thumbCenter.dx;
    final double activeEnd = textDirection == TextDirection.ltr
        ? thumbCenter.dx
        : track.right;

    final Paint activeLine = Paint()
      ..color = activeColor
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final Paint inactiveLine = Paint()
      ..color = inactiveColor
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final Paint activeFill = Paint()..color = activeColor;
    final Paint inactiveFill = Paint()..color = inactiveColor;

    void line(double from, double to, Paint paint) {
      if (to - from <= 0) return;
      canvas.drawLine(Offset(from, cy), Offset(to, cy), paint);
    }

    final double spacing = track.width / (nodes - 1);

    for (int i = 0; i < nodes - 1; i++) {
      final double start = track.left + i * spacing;
      final double end = track.left + (i + 1) * spacing;
      // Split into at most three runs, so a segment straddling the thumb is
      // part filled and part not.
      line(start, math.min(end, activeStart), inactiveLine);
      line(math.max(start, activeStart), math.min(end, activeEnd), activeLine);
      line(math.max(start, activeEnd), end, inactiveLine);
    }

    for (int i = 0; i < nodes; i++) {
      final double cx = track.left + i * spacing;
      final bool reached =
          cx >= activeStart - _epsilon && cx <= activeEnd + _epsilon;
      canvas.drawPath(
        _diamond(cx, cy, nodeSize),
        reached ? activeFill : inactiveFill,
      );
    }
  }
}

/// A slider thumb drawn as a diamond that leans the way it is being dragged.
///
/// [angle] is set by the widget from the drag direction and animated, so the
/// thumb tips into the movement and returns to level when released. Hold it at
/// `0` for a thumb that never tilts.
class DiamondSliderThumbShape extends SliderComponentShape {
  /// Creates a diamond thumb.
  const DiamondSliderThumbShape({
    required this.color,
    required this.borderColor,
    this.size = 14,
    this.borderWidth = 1.5,
    this.angle = 0,
  }) : assert(size > 0),
       assert(borderWidth >= 0);

  /// The diamond's width and height, and the size the track is inset by.
  final double size;

  /// The diamond's fill.
  final Color color;

  /// The diamond's outline, drawn only when [borderWidth] is above zero.
  final Color borderColor;

  /// The outline's width. `0` drops it.
  final double borderWidth;

  /// How far the diamond is rotated, in radians.
  final double angle;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.square(size);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    // The outline straddles the path, so the diamond is inset by half its
    // width — otherwise a thick border grows the thumb past its stated size.
    final double drawn = size - borderWidth;
    final Path path = _diamond(0, 0, drawn <= 0 ? size : drawn);

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angle)
      ..drawPath(path, Paint()..color = color);
    if (borderWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
  }
}

/// A slider tick mark drawn as a small diamond.
///
/// `DiamondPercentSlider` does not use this — its diamonds come from
/// [DiamondSliderTrackShape], which draws a fixed number of them however many
/// divisions the slider has. It is here for a plain [Slider] with few enough
/// divisions to want one mark each.
class DiamondSliderTickMarkShape extends SliderTickMarkShape {
  /// Creates a diamond tick mark.
  const DiamondSliderTickMarkShape({required this.color, this.size = 8})
    : assert(size > 0);

  /// The diamond's width and height.
  final double size;

  /// The diamond's fill.
  final Color color;

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) => Size.square(size);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required bool isEnabled,
    required TextDirection textDirection,
  }) => context.canvas.drawPath(
    _diamond(center.dx, center.dy, size),
    Paint()..color = color,
  );
}

/// A slider value indicator drawn as a rounded bubble above the thumb, which
/// scales and fades in as the thumb is pressed.
///
/// Unlike the framework's, it is a plain rectangle rather than a teardrop, it
/// sits a fixed gap above the thumb, and the whole bubble — text included —
/// fades together.
class DiamondSliderValueIndicatorShape extends SliderComponentShape {
  /// Creates a bubble indicator.
  const DiamondSliderValueIndicatorShape({
    required this.color,
    this.radius = 6,
    this.gap = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.minWidth = 30,
  }) : assert(radius >= 0),
       assert(minWidth >= 0);

  /// The bubble's fill.
  final Color color;

  /// The bubble's corner radius.
  final double radius;

  /// The gap between the thumb and the bubble's bottom edge.
  final double gap;

  /// The inset between the text and the bubble's edges.
  final EdgeInsets padding;

  /// The narrowest the bubble may be, however short its text.
  final double minWidth;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(minWidth, padding.vertical + gap);

  Size _sizeFor(TextPainter labelPainter) {
    labelPainter.layout();
    final Size text = labelPainter.size;
    return Size(
      math.max(text.width + padding.horizontal, minWidth),
      text.height + padding.vertical,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final double t = activationAnimation.value;
    if (t == 0) return;

    final Canvas canvas = context.canvas;
    final Size bubble = _sizeFor(labelPainter);
    final Offset origin = Offset(
      thumbCenter.dx - bubble.width / 2,
      thumbCenter.dy - bubble.height - gap,
    );
    final Rect rect = origin & bubble;

    // One layer for the whole bubble, so the text fades with the background
    // rather than appearing at full strength over a translucent box.
    canvas
      ..saveLayer(
        rect.inflate(radius),
        Paint()..color = const Color(0xFF000000).withValues(alpha: t),
      )
      ..save()
      ..translate(thumbCenter.dx, thumbCenter.dy)
      ..scale(0.8 + 0.2 * t)
      ..translate(-thumbCenter.dx, -thumbCenter.dy)
      ..drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = color,
      );
    labelPainter.paint(
      canvas,
      origin +
          Offset(
            (bubble.width - labelPainter.width) / 2,
            (bubble.height - labelPainter.height) / 2,
          ),
    );
    canvas
      ..restore()
      ..restore();
  }
}
