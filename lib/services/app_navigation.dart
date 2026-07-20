import 'package:flutter/widgets.dart';

/// The app's single [NavigatorState], shared outside the widget tree.
///
/// `main.dart` wires this into `MaterialApp.navigatorKey`. Service-layer
/// code that has no `BuildContext` of its own (e.g. showing a dialog in
/// response to a subscription-profile update) can reach the current
/// navigator/context through this key instead.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
