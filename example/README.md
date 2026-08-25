# diamond_percent_slider_example

A runnable demo of [`diamond_percent_slider`](../), showing the slider in the
configurations the package README describes: the plain percent scale, a
labelled scale, a leverage picker with `x` labels, coarse steps, a custom tint,
the disabled state, and the light and dark colour defaults. The app bar
toggles the theme's brightness and the text direction, so the right-to-left
layout is one tap away.

## Run it

```sh
flutter run
```

The demo depends on the package by path, so edits to `../lib` show up on the
next hot reload.

## Screenshots

`test/screenshots_test.dart` renders the images in the package README from
these same widgets. Regenerate them after changing how the slider draws:

```sh
flutter test --update-goldens test/screenshots_test.dart
```

The goldens land in `../screenshots/`. They are compared, not just written, so
plain `flutter test` fails when the rendering changes unintentionally.
