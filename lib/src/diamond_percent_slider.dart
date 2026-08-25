import 'package:material_ui/material_ui.dart';

import 'diamond_slider_shapes.dart';
import 'diamond_slider_theme.dart';

/// Formats an integer value for display — on the scale under the track, or in
/// the bubble above the thumb.
typedef DiamondSliderLabelFormatter = String Function(int value);

/// An integer slider on a scale of diamonds, with a diamond thumb that leans
/// the way it is dragged and a bubble showing the value while it moves.
///
/// ```dart
/// DiamondPercentSlider(
///   value: percent,
///   onChanged: (value) => setState(() => percent = value),
/// )
/// ```
///
/// The scale is decoration and the range is not: [nodes] diamonds are drawn
/// however wide [min] to [max] is, and each node's label is the value at that
/// point. Five nodes over 0–100 label 0, 25, 50, 75 and 100; five over 1–20
/// label 1, 6, 11, 15 and 20.
///
/// Values are integers, stepped by [step]. Everything else — keyboard support,
/// the drag gesture, semantics — is the framework's [Slider] underneath, so it
/// behaves like one.
///
/// ```dart
/// // Leverage, labelled, in steps of five.
/// DiamondPercentSlider(
///   value: leverage,
///   min: 5,
///   max: 100,
///   step: 5,
///   nodes: 5,
///   showLabels: true,
///   labelFormatter: (value) => '${value}x',
///   onChanged: (value) => setState(() => leverage = value),
/// )
/// ```
class DiamondPercentSlider extends StatefulWidget {
  /// Creates a diamond slider.
  ///
  /// [value] is clamped into [min]–[max] for display, so a host that has not
  /// caught up with a changed range still renders something sensible.
  ///
  /// A null [onChanged] disables the slider, as it does on [Slider]; [enabled]
  /// is the other way to say so, for a host whose callback is constant.
  const DiamondPercentSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.nodes = 5,
    this.enabled = true,
    this.showLabels = false,
    this.labelFormatter,
    this.indicatorFormatter,
    this.semanticFormatter,
    this.onChangeStart,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.indicatorColor,
    this.labelStyle,
    super.key,
  }) : assert(max > min, 'max has to be above min'),
       assert(step > 0, 'step has to be positive'),
       assert(nodes >= 2, 'a scale needs at least its two ends'),
       assert(
         (max - min) % step == 0,
         'step has to divide the range, or max is not reachable',
       );

  /// The current value. Clamped into [min]–[max] for display.
  final int value;

  /// Called with each new value as the thumb moves. Null disables the slider.
  final ValueChanged<int>? onChanged;

  /// The lowest value, at the first node.
  final int min;

  /// The highest value, at the last node.
  final int max;

  /// The gap between selectable values. Must divide `max - min`.
  final int step;

  /// How many diamonds the scale is drawn with, ends included.
  ///
  /// Independent of [step]: a 0–100 slider in steps of 1 still reads clearly
  /// with five nodes.
  final int nodes;

  /// Whether the slider responds to input. A null [onChanged] also disables it.
  final bool enabled;

  /// Whether each node is labelled with the value at that point.
  final bool showLabels;

  /// Formats the node labels and, unless [indicatorFormatter] says otherwise,
  /// the bubble. Defaults to `'42%'`.
  final DiamondSliderLabelFormatter? labelFormatter;

  /// Formats the bubble above the thumb, when it should read differently from
  /// the scale labels.
  final DiamondSliderLabelFormatter? indicatorFormatter;

  /// What a screen reader announces for a value. Defaults to
  /// [indicatorFormatter], then [labelFormatter].
  final DiamondSliderLabelFormatter? semanticFormatter;

  /// Called with the value the drag started from.
  final ValueChanged<int>? onChangeStart;

  /// Called with the value the drag ended on.
  final ValueChanged<int>? onChangeEnd;

  /// The focus node for keyboard control.
  final FocusNode? focusNode;

  /// Whether to take focus on first build.
  final bool autofocus;

  /// Overrides the theme's active colour for this slider alone.
  final Color? activeColor;

  /// Overrides the theme's inactive colour for this slider alone.
  final Color? inactiveColor;

  /// Overrides the theme's thumb colour for this slider alone.
  final Color? thumbColor;

  /// Overrides the theme's bubble colour for this slider alone.
  final Color? indicatorColor;

  /// Overrides the theme's label style for this slider alone.
  final TextStyle? labelStyle;

  /// The value at node [index] of [nodes], on a [min]–[max] scale.
  ///
  /// The same arithmetic the labels use, exposed so a host can put its own
  /// marks under a slider and have them line up.
  static int valueAtNode({
    required int index,
    required int nodes,
    required int min,
    required int max,
  }) {
    assert(nodes >= 2);
    assert(index >= 0 && index < nodes);
    if (index == 0) return min;
    if (index == nodes - 1) return max;
    return (min + (max - min) * index / (nodes - 1)).round();
  }

  @override
  State<DiamondPercentSlider> createState() => _DiamondPercentSliderState();
}

class _DiamondPercentSliderState extends State<DiamondPercentSlider> {
  /// -1, 0 or 1: which way the thumb is leaning, before the angle is applied.
  double _tilt = 0;

  bool get _interactive => widget.enabled && widget.onChanged != null;

  int get _clampedValue => widget.value.clamp(widget.min, widget.max);

  int get _divisions => (widget.max - widget.min) ~/ widget.step;

  DiamondSliderLabelFormatter get _label => widget.labelFormatter ?? _percent;

  DiamondSliderLabelFormatter get _indicator =>
      widget.indicatorFormatter ?? _label;

  static String _percent(int value) => '$value%';

  /// Snaps [raw] to the nearest step, which the divisions have already all but
  /// done — this only turns the double back into the stepped integer.
  int _snap(double raw) {
    final int steps = ((raw - widget.min) / widget.step).round();
    return (widget.min + steps * widget.step).clamp(widget.min, widget.max);
  }

  void _handleChanged(double raw) {
    final int next = _snap(raw);
    final int current = _clampedValue;
    if (next == current) return;
    _lean(next > current ? 1 : -1);
    widget.onChanged?.call(next);
  }

  void _lean(double direction) {
    if (_tilt == direction) return;
    setState(() => _tilt = direction);
  }

  void _handleChangeStart(double raw) => widget.onChangeStart?.call(_snap(raw));

  void _handleChangeEnd(double raw) {
    _lean(0);
    widget.onChangeEnd?.call(_snap(raw));
  }

  @override
  Widget build(BuildContext context) {
    final DiamondSliderTheme theme = DiamondSliderTheme.of(context).copyWith(
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
      thumbColor: widget.thumbColor,
      indicatorColor: widget.indicatorColor,
      labelStyle: widget.labelStyle,
    );
    final TextTheme text = Theme.of(context).textTheme;

    // Disabled colours are resolved here rather than through the shapes'
    // enableAnimation, so the scale labels fade with the track instead of
    // staying bright over a greyed-out slider.
    final Color active = _interactive
        ? theme.activeColor!
        : theme.disabledColor!;
    final Color inactive = _interactive
        ? theme.inactiveColor!
        : theme.disabledColor!.withValues(alpha: theme.disabledOpacity / 2);

    final TextStyle labelStyle = (text.bodySmall ?? const TextStyle())
        .copyWith(
          color: _interactive ? theme.labelColor : theme.disabledColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        )
        .merge(theme.labelStyle);

    final Widget slider = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _tilt * theme.tiltAngle),
      duration: theme.tiltDuration,
      curve: theme.tiltCurve,
      builder: (BuildContext context, double angle, Widget? child) =>
          SliderTheme(
            data: SliderThemeData(
              // Non-transparent on purpose: BaseSliderTrackShape collapses the
              // track rect to zero height when both are transparent, and the
              // nodes are measured against that rect.
              activeTrackColor: active,
              inactiveTrackColor: inactive,
              trackHeight: theme.nodeSize > theme.trackThickness
                  ? theme.nodeSize
                  : theme.trackThickness,
              overlayColor: theme.overlayColor,
              trackShape: DiamondSliderTrackShape(
                nodes: widget.nodes,
                activeColor: active,
                inactiveColor: inactive,
                nodeSize: theme.nodeSize,
                thickness: theme.trackThickness,
              ),
              thumbShape: DiamondSliderThumbShape(
                size: theme.thumbSize,
                color: _interactive
                    ? theme.thumbColor!
                    : Color.alphaBlend(
                        theme.disabledColor!.withValues(alpha: 0.12),
                        theme.thumbColor!,
                      ),
                borderColor: active,
                borderWidth: theme.thumbBorderWidth,
                angle: angle,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: theme.overlayRadius,
              ),
              // The scale already shows every node it means to; a mark per
              // division on top would be noise, and at 100 divisions a smear.
              tickMarkShape: SliderTickMarkShape.noTickMark,
              valueIndicatorShape: DiamondSliderValueIndicatorShape(
                color: theme.indicatorColor!,
                radius: theme.indicatorRadius,
                gap: theme.indicatorGap,
                padding: theme.indicatorPadding,
                minWidth: theme.indicatorMinWidth,
              ),
              valueIndicatorTextStyle: (text.labelSmall ?? const TextStyle())
                  .copyWith(
                    color: theme.indicatorTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )
                  .merge(theme.indicatorTextStyle),
            ),
            child: Slider(
              value: _clampedValue.toDouble(),
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: _divisions,
              label: _indicator(_clampedValue),
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              semanticFormatterCallback: (double raw) =>
                  (widget.semanticFormatter ?? _indicator)(_snap(raw)),
              onChanged: _interactive ? _handleChanged : null,
              onChangeStart: _interactive ? _handleChangeStart : null,
              onChangeEnd: _interactive ? _handleChangeEnd : null,
            ),
          ),
    );

    if (!widget.showLabels) return RepaintBoundary(child: slider);

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          slider,
          SizedBox(height: theme.labelSpacing),
          _ScaleLabels(
            nodes: widget.nodes,
            min: widget.min,
            max: widget.max,
            formatter: _label,
            style: labelStyle,
            // The track is inset from the slider's edges by half the wider of
            // the thumb and the overlay, which is where BaseSliderTrackShape
            // puts it. Matching that inset is what lines a label up with its
            // node.
            inset:
                (theme.thumbSize > theme.overlayRadius * 2
                    ? theme.thumbSize
                    : theme.overlayRadius * 2) /
                2,
          ),
        ],
      ),
    );
  }
}

/// The values of the scale's nodes, laid out under their diamonds.
class _ScaleLabels extends StatelessWidget {
  const _ScaleLabels({
    required this.nodes,
    required this.min,
    required this.max,
    required this.formatter,
    required this.style,
    required this.inset,
  });

  final int nodes;
  final int min;
  final int max;
  final DiamondSliderLabelFormatter formatter;
  final TextStyle style;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      for (int i = 0; i < nodes; i++)
        formatter(
          DiamondPercentSlider.valueAtNode(
            index: i,
            nodes: nodes,
            min: min,
            max: max,
          ),
        ),
    ];

    // Every label is positioned, so the row needs a height of its own. Measured
    // rather than guessed, so it follows the style and the text scale.
    final TextPainter probe = TextPainter(
      text: TextSpan(text: labels.first, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double height = probe.height;
    probe.dispose();

    // Decoration: the slider itself announces its value, and a screen reader
    // reading the scale out as well would only be in the way.
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: inset, end: inset),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                // The end labels are centred on the track's ends, so half of
                // each hangs over the padding this widget sits inside.
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (int i = 0; i < nodes; i++)
                    // Directional, not `left`: under RTL the slider puts min
                    // on the right, and the labels have to follow the values
                    // rather than the pixels.
                    PositionedDirectional(
                      start: width * i / (nodes - 1),
                      top: 0,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Text(
                          labels[i],
                          style: style,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
