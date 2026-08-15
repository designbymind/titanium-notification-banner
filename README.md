# Titanium Notification Banner

A lightweight native notification banner for Titanium Mobile on iOS and Android.

## Requirements

- Titanium 12.0.0+
- iOS implementation uses scene-aware UIKit APIs and is compatible with modern safe-area/status-bar layouts, including iOS 27.

## Example

```js
import NotificationBanner from 'ti.notificationbanner';

NotificationBanner.show({
  title: 'Chat Request Sent',
  subtitle: 'Tap to view',
  duration: 3,
  backgroundColor: '#ffffff',
  titleColor: '#000000',
  minimumHeight: 80,
  onClick() => {
    // Handle tap
  }
});
```

## Methods

- `show(options)`

## Properties

- `title` (Optional) - Banner title.
- `subtitle` (Optional) - Banner subtitle.
- `image` (Optional) - Titanium image path displayed at the left of the text.
- `backgroundColor` (Optional) - Banner background color. Defaults to black.
- `titleColor` (Optional) - Text and image tint color. Defaults to white.
- `duration` (Optional) - Automatic dismissal delay in seconds. Omit to keep the banner visible until dismissed by tap/swipe.
- `minimumHeight` (Optional) - Minimum total banner height in points. Defaults to `80`.
- `onClick` (Optional) - Callback invoked when the banner is tapped.

## iOS 27

The iOS implementation no longer relies on BRYXBanner's deprecated `UIApplication.statusBarFrame`, `UIApplication.statusBarStyle`, or global-window layout assumptions. It resolves the active `UIWindowScene`, uses the window safe-area inset first, and falls back to `UIStatusBarManager` when necessary.

The original prebuilt BRYXBanner framework remains in the repository for historical/build compatibility, but the Titanium iOS module no longer imports or executes it. The banner implementation is now self-contained in `ios/Classes/TiNotificationbannerModule.swift`.

## License

MIT

## Author

Hans Knöchel, Lambus GmbH & DesignByMind
