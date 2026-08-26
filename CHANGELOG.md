## 1.1.0

Two fixes and a handful of additions. Nothing in 1.0.x behaves differently
unless it was relying on one of the bugs.

**Fixed**

* `DiamondSliderTheme.thumbBorderColor` now reaches the thumb. It was declared,
  resolved and lerped, but the widget drew the outline in the active colour, so
  setting it in a registered extension did nothing. Left unset, the outline
  still follows the active colour — including a per-instance `activeColor`.
* The thumb leans the way the finger moves under RTL. It was picking its lean
  from the direction of the *value*, so in an RTL locale it tipped away from the
  drag.

**Added**

* `enableFeedback` (default `true`): a haptic tick on each step change.
* `thumbBorderColor` on the widget, to override the theme for one slider — the
  other colours already had a per-instance form.
* `mouseCursor`, `allowedInteraction` and `padding` pass through to the
  underlying `Slider`. The scale labels are inset to match `padding`, so they
  keep lining up with their nodes.

**Changed**

* The scale labels' row is measured against the tallest label rather than the
  first, so a formatter returning labels of differing heights is not clipped.
* The thumb's tilt no longer rebuilds the whole slider each frame: the theme and
  the `Slider` are hoisted out of the animation, leaving one shape allocation
  per frame.
* Documented the label-crowding and localisation stances, and added golden tests
  and a CI workflow (`dart format`, `flutter analyze`, `flutter test`,
  `dart pub publish --dry-run`, `pana`).

## 1.0.1

* No API or behaviour changes.
* Formatted the source with `dart format`, so the package scores full marks on
  `pana`.
* Documented the supported platforms: `material_ui` reaches for `dart:io`, so
  the slider runs on Android, iOS, macOS, Windows and Linux, but not web.

## 1.0.0

* First stable release of the diamond percent slider.
* Adds a theme extension, custom track, thumb, tick-mark and value-indicator
  shapes, keyboard and semantic support, and a runnable example.
