import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/hoyolab/models/game_record.dart';
import '../../domain/character_list_sort.dart';
import '../../providers/character_list_sort_providers.dart';
import '../../providers/hoyolab_game_providers.dart';
import '../../../providers/hoyolab_game_refresh.dart';
import 'widgets/character_list_sort_sheet.dart';

class CharacterListScreen extends ConsumerWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(sortedCharacterEntriesProvider);
    final ownedFetchAsync = ref.watch(hoyolabOwnedFetchResultProvider);
    final sortSettingsAsync = ref.watch(characterListSortSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター'),
        actions: [
          if (sortSettingsAsync.valueOrNull case final settings?)
            IconButton(
              icon: const Icon(Icons.sort),
              tooltip: '並び替え',
              onPressed: () => showCharacterListSortSheet(
                context: context,
                settings: settings,
                onChanged: (CharacterListSortSettings next) => ref
                    .read(characterListSortSettingsProvider.notifier)
                    .updateSettings(next),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '所持情報を更新',
            onPressed: () => refreshHoyolabOwnedCharacters(ref),
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('キャラデータがありません'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/settings'),
                    child: const Text('設定で同期する'),
                  ),
                ],
              ),
            );
          }

          final settings =
              sortSettingsAsync.valueOrNull ?? const CharacterListSortSettings();
          final showSections = shouldShowOwnershipSections(settings);
          final ownedLen = ownedEntryCount(entries);
          final hasOwned = ownedLen > 0;
          final hasUnowned = ownedLen < entries.length;
          final fetchMessage = ownedFetchAsync.maybeWhen(
            data: (result) => result.userMessage,
            orElse: () => null,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sortSettingsAsync.hasValue)
                _SortSummaryBar(settings: settings),
              Expanded(
                child: ListView.builder(
                  itemCount: _itemCount(
                    entries,
                    showSections: showSections,
                    hasOwned: hasOwned,
                    hasUnowned: hasUnowned,
                    showBanner: fetchMessage != null,
                  ),
                  itemBuilder: (context, index) {
                    if (fetchMessage != null && index == 0) {
                      return _OwnedFetchBanner(message: fetchMessage);
                    }
                    final listIndex =
                        fetchMessage != null ? index - 1 : index;
                    final item = _resolveItem(
                      entries,
                      listIndex,
                      showSections: showSections,
                      hasOwned: hasOwned,
                      hasUnowned: hasUnowned,
                      ownedLen: ownedLen,
                    );
                    if (item is _SectionHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          item.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      );
                    }

                    final entry = item as CharacterListEntry;
                    final c = entry.character;
                    final ownedLabel = _ownedSubtitle(entry);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(c.iconUrl),
                      ),
                      title: Text(c.name),
                      subtitle: Text(
                        ownedLabel ?? '${c.region} · ${c.rarity}★',
                      ),
                      trailing: entry.isOwned
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Text(c.element),
                      onTap: () => context.go('/characters/${c.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }

  String? _ownedSubtitle(CharacterListEntry entry) {
    final owned = entry.owned;
    if (owned == null) return null;
    final obtained = formatRelativeObtained(owned.obtainedAt);
    if (obtained != null) {
      return '${entry.character.rarity}★ · Lv.${owned.level} · $obtained';
    }
    return '${entry.character.rarity}★ · Lv.${owned.level} · 所持';
  }

  int _itemCount(
    List<CharacterListEntry> entries, {
    required bool showSections,
    required bool hasOwned,
    required bool hasUnowned,
    bool showBanner = false,
  }) {
    var count = entries.length;
    if (showBanner) count += 1;
    if (showSections && hasOwned) count += 1;
    if (showSections && hasUnowned) count += 1;
    return count;
  }

  Object _resolveItem(
    List<CharacterListEntry> entries,
    int index, {
    required bool showSections,
    required bool hasOwned,
    required bool hasUnowned,
    required int ownedLen,
  }) {
    var cursor = 0;

    if (showSections && hasOwned) {
      if (index == cursor) {
        return const _SectionHeader('所持キャラクター');
      }
      cursor++;
    }

    if (showSections) {
      final ownedEntries = entries.take(ownedLen);
      if (index < cursor + ownedLen) {
        return ownedEntries.elementAt(index - cursor);
      }
      cursor += ownedLen;

      if (hasUnowned) {
        if (index == cursor) {
          return const _SectionHeader('未所持キャラクター');
        }
        cursor++;
        return entries.skip(ownedLen).elementAt(index - cursor);
      }

      return entries.last;
    }

    return entries[index];
  }
}

class _SortSummaryBar extends StatelessWidget {
  const _SortSummaryBar({required this.settings});

  final CharacterListSortSettings settings;

  @override
  Widget build(BuildContext context) {
    final groupLabel =
        settings.groupByOwnership ? 'グループ分けあり' : '一覧表示';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.sort,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${settings.mode.label} · $groupLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader {
  const _SectionHeader(this.title);

  final String title;
}

class _OwnedFetchBanner extends StatelessWidget {
  const _OwnedFetchBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
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
