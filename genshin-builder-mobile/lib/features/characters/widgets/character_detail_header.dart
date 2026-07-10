import 'package:flutter/material.dart';

import '../../../data/amber/amber_constants.dart';
import '../../../data/models/master_models.dart';
import '../../shared/game_icon_image.dart';

/// キャラ詳細画面上部: アイコン・名前・元素・レア度・武器種
class CharacterDetailHeader extends StatelessWidget {
  const CharacterDetailHeader({super.key, required this.character});

  final MasterCharacter character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elementLabel =
        elementLabelMap[character.element] ?? character.element;
    final weaponLabel =
        weaponTypeLabelMap[character.weaponType] ?? character.weaponType;
    final elementColor = elementColorMap.containsKey(character.element)
        ? Color(elementColorMap[character.element]!)
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GameIconImage(iconUrl: character.iconUrl, size: 72, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label: elementLabel,
                      background: elementColor.withValues(alpha: 0.18),
                      foreground: elementColor,
                    ),
                    _InfoChip(
                      label: '${character.rarity}★',
                      background: theme.colorScheme.primaryContainer,
                      foreground: theme.colorScheme.onPrimaryContainer,
                    ),
                    _InfoChip(
                      label: weaponLabel,
                      background: theme.colorScheme.surfaceContainerHighest,
                      foreground: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
