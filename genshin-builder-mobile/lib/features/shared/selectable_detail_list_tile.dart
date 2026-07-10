import 'package:flutter/material.dart';

/// 選択タップと詳細タップを分離したリスト行。
/// 武器選択・将来の聖遺物選択で同じ UI パターンを使う。
class SelectableDetailListTile extends StatelessWidget {
  const SelectableDetailListTile({
    super.key,
    required this.title,
    required this.onSelect,
    required this.onDetail,
    this.leading,
    this.subtitle,
    this.isEquipped = false,
    this.equippedLabel = '装備中',
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool isEquipped;
  final String equippedLabel;
  final VoidCallback onSelect;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onSelect,
      leading: leading,
      title: Text(title, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (isEquipped)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                equippedLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      isThreeLine: isEquipped && subtitle != null,
      trailing: IconButton(
        tooltip: '詳細',
        icon: const Icon(Icons.info_outline),
        onPressed: onDetail,
      ),
    );
  }
}
