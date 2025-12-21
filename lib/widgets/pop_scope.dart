import 'package:flutter/widgets.dart';

/// A small compatibility wrapper named `PopScope` that preserves the
/// existing `WillPopScope`-based `onWillPop` behavior while allowing the
/// codebase to refer to `PopScope` throughout. This avoids a large,
/// risky migration to framework `PopScope` APIs while keeping a single
/// abstraction point for a future proper refactor.
class CompatPopScope extends StatelessWidget {
  final Widget child;
  final WillPopCallback? onWillPop;

  const CompatPopScope({super.key, required this.child, this.onWillPop});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: onWillPop, child: child);
  }
}
