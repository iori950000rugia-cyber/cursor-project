import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(aggregatedBookmarksProvider);
    final fmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('素材ブックマーク')),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return const Center(
              child: Text('ブックマークされた素材はありません'),
            );
          }
          return ListView.separated(
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final b = bookmarks[index];
              return ListTile(
                leading: b.isMora
                    ? const CircleAvatar(child: Text('M'))
                    : (b.iconUrl != null
                        ? CachedNetworkImage(
                            imageUrl: b.iconUrl!,
                            width: 40,
                            height: 40,
                          )
                        : const Icon(Icons.inventory_2)),
                title: Text(b.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.sourceLabels.join('\n')),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: b.characters
                          .map(
                            (c) => Chip(
                              avatar: c.characterIconUrl != null
                                  ? CircleAvatar(
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                        c.characterIconUrl!,
                                      ),
                                    )
                                  : null,
                              label: Text(c.characterName),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                trailing: Text(
                  fmt.format(b.count),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}
