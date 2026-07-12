import 'package:flutter/material.dart';

import '../../router.dart';

/// AppShell の右側ドロワーを開く AppBar 用ボタン。
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'メニュー',
      onPressed: () => AppShellScope.openEndDrawer(context),
    );
  }
}
