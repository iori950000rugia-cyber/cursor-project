import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/game_icon_image.dart';

/// キャラアイコン。育成完了時は右上にチェック。
class CharacterIconWithBadge extends StatelessWidget {
  const CharacterIconWithBadge({
    super.key,
    required this.characterId,
    this.iconUrl,
    this.name,
    this.completed = false,
    this.size = 44,
  });

  final String characterId;
  final String? iconUrl;
  final String? name;
  final bool completed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: name ?? '',
      child: InkWell(
        onTap: () => context.push('/characters/$characterId'),
        borderRadius: BorderRadius.circular(size / 4),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GameIconImage(
                iconUrl: iconUrl,
                size: size,
                borderRadius: size / 5,
                fallback: Text(
                  (name != null && name!.isNotEmpty) ? name![0] : '?',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              if (completed)
                Positioned(
                  right: -2,
                  top: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: size * 0.32,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
