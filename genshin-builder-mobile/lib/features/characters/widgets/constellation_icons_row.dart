import 'package:flutter/material.dart';

import '../../../domain/models/amber_detail_models.dart';
import '../../shared/game_icon_image.dart';

/// Constellation icon row (1-6). Tap for effect details.
class ConstellationIconsRow extends StatelessWidget {
  const ConstellationIconsRow({
    super.key,
    required this.unlockedCount,
    required this.elementColor,
    this.constellations = const [],
    this.iconSize = 22,
    this.spacing = 4,
  });

  /// 取得済み凸数（0〜6）。表示状態。API 値とは呼び出し側で分離する。
  final int unlockedCount;

  final Color elementColor;
  final List<ConstellationDetailData> constellations;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final count = unlockedCount.clamp(0, 6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 6; i++) ...[
          if (i > 1) SizedBox(width: spacing),
          _ConstellationIconButton(
            position: i,
            unlocked: i <= count,
            elementColor: elementColor,
            size: iconSize,
            detail: i <= constellations.length ? constellations[i - 1] : null,
          ),
        ],
      ],
    );
  }
}

class _ConstellationIconButton extends StatelessWidget {
  const _ConstellationIconButton({
    required this.position,
    required this.unlocked,
    required this.elementColor,
    required this.size,
    this.detail,
  });

  final int position;
  final bool unlocked;
  final Color elementColor;
  final double size;
  final ConstellationDetailData? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimColor = theme.colorScheme.onSurface.withValues(alpha: 0.28);

    return Tooltip(
      message: '命ノ星座 第$position重',
      child: InkWell(
        onTap: () => _showDetail(context),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size + 4,
          height: size + 4,
          child: Center(
            child: detail?.iconUrl != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      unlocked ? elementColor : dimColor,
                      BlendMode.srcATop,
                    ),
                    child: GameIconImage(
                      iconUrl: detail!.iconUrl,
                      size: size,
                    ),
                  )
                : Icon(
                    unlocked ? Icons.circle : Icons.circle_outlined,
                    size: size * 0.85,
                    color: unlocked ? elementColor : dimColor,
                  ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final theme = Theme.of(context);
    final name = detail?.name;
    final description = detail?.description;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (detail?.iconUrl != null) ...[
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        unlocked ? elementColor : theme.colorScheme.onSurface,
                        BlendMode.srcATop,
                      ),
                      child: GameIconImage(
                        iconUrl: detail!.iconUrl,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '命ノ星座 第$position重',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          unlocked ? '取得済み' : '未解放',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: unlocked
                                ? elementColor
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('効果名', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                (name == null || name.isEmpty) ? '（名称未取得）' : name,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text('効果説明', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                (description == null || description.isEmpty)
                    ? '効果説明を取得できませんでした。ネットワーク接続を確認するか、画面を開き直してください。'
                    : description,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}
