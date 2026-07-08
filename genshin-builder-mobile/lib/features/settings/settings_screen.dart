import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;
  String? _lastMessage;

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _lastMessage = null;
    });
    try {
      final service = await ref.read(masterSyncServiceProvider.future);
      final result = await service.syncMasterData();
      ref.invalidate(charactersProvider);
      ref.invalidate(lastSyncTimeProvider);
      ref.invalidate(aggregatedBookmarksProvider);
      setState(() {
        _lastMessage = result.hasErrors
            ? '一部エラー: ${result.errors.join('; ')}'
            : '同期完了: キャラ ${result.characters} / 武器 ${result.weapons} / 素材 ${result.materials}';
      });
    } catch (e) {
      setState(() => _lastMessage = '同期失敗: $e');
    } finally {
      setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastSyncAsync = ref.watch(lastSyncTimeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'マスターデータ同期',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Project Amber (gi.yatta.moe) からキャラ・武器・素材を取得します。',
                  ),
                  const SizedBox(height: 8),
                  lastSyncAsync.when(
                    data: (dt) => Text(
                      dt == null
                          ? '未同期'
                          : '最終同期: ${dt.toLocal()}',
                    ),
                    loading: () => const Text('…'),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _syncing ? null : _sync,
                    icon: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download),
                    label: Text(_syncing ? '同期中…' : '今すぐ同期'),
                  ),
                  if (_lastMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_lastMessage!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: const Text('HoYoLAB 連携'),
              subtitle: const Text('樹脂・デイリー・派遣の表示'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/hoyolab'),
            ),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.warning_amber),
            title: Text('免責事項'),
            subtitle: Text(
              '本アプリは非公式ツールです。ゲームデータの正確性は保証されません。',
            ),
          ),
        ],
      ),
    );
  }
}
