import 'package:flutter/material.dart';

class TrialTabScroll extends StatelessWidget {
  final Widget child;

  const TrialTabScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: child),
      ),
    );
  }
}
