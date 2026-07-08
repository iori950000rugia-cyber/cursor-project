import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/sync_status.dart';
import '../../data/sync/master_sync_runner.dart';
import '../../providers/app_providers.dart';

/// 初回起動時のマスタ同期・アイコン事前読み込み
class InitialSyncScreen extends ConsumerStatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  ConsumerState<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends ConsumerState<InitialSyncScreen> {
  bool _running = false;
  String? _error;
  SyncProgress? _syncProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_running) return;

    final status = await ref.read(syncStatusProvider.future);
    if (!status.isUnsynced && !status.needsInitialUpgradeSync) {
      if (mounted) context.go('/');
      return;
    }

    await _runInitialSync();
  }

  Future<void> _runInitialSync() async {
    setState(() {
      _running = true;
      _error = null;
      _syncProgress = null;
    });

    try {
      final outcome = await runMasterSyncWithIconPreload(
        ref,
        onProgress: (p) {
          if (mounted) setState(() => _syncProgress = p);
        },
      );
      final result = outcome.result;

      if (!mounted) return;

      if (result.characters == 0) {
        setState(() {
          _error = result.hasErrors
              ? '同期に失敗しました: ${result.errors.join('; ')}'
              : 'キャラデータを取得できませんでした。ネットワーク接続を確認してください。';
        });
        return;
      }

      context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() => _error = '初期同期に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          if (_error == null) {
            _syncProgress = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.cloud_download_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '初回セットアップ',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'キャラ・武器・素材のマスタデータを取得し、アイコンを読み込んでいます。'
                '初回のみ数分かかることがあります。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_syncProgress != null) ...[
                Text(
                  _syncProgress!.displayLabel,
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _syncProgress!.displayFraction,
                ),
              ] else if (_running) ...[
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: 24),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _running ? null : _runInitialSync,
                  child: const Text('再試行'),
                ),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
