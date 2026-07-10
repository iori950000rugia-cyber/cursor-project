import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/user_facing_error.dart';
import '../../data/models/sync_status.dart';
import '../../data/sync/master_content_probe.dart';
import '../../data/sync/master_sync_runner.dart';
import '../../providers/app_providers.dart';

/// 起動時のマスタ同期・アイコン事前読み込み
///
/// - ローカル未同期 / 突破不足 → 自動同期
/// - それ以外 → Amber 一覧件数をプローブし、新コンテンツがあれば自動同期
class InitialSyncScreen extends ConsumerStatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  ConsumerState<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends ConsumerState<InitialSyncScreen> {
  bool _running = false;
  String? _error;
  String? _subtitle;
  SyncProgress? _syncProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_running) return;

    final status = await ref.read(syncStatusProvider.future);
    if (status.shouldAutoSyncOnLaunch) {
      setState(() {
        _subtitle = status.isUnsynced
            ? 'キャラ・武器・素材のマスタデータを取得し、アイコンを読み込んでいます。'
            : '不足している突破データを取得しています。';
      });
      await _runSync();
      return;
    }

    // ローカルは揃っているが、リモートに新キャラ等が増えていないか確認
    setState(() {
      _subtitle = 'ゲームデータの更新を確認しています…';
      _running = true;
    });

    try {
      final db = await ref.read(appDatabaseProvider.future);
      final amber = ref.read(amberApiProvider);
      final probe = await MasterContentProbe(amberApi: amber, db: db).check();

      if (!mounted) return;

      if (probe.shouldSync) {
        setState(() {
          _running = false;
          _subtitle =
              '新しいゲームデータを検出しました（${probe.reasonSummary}）。同期します…';
        });
        await _runSync();
        return;
      }
    } catch (e, st) {
      logAppError(e, st, 'initialSync.probe');
      // プローブ失敗時はホームへ（手動同期に委ねる）
    }

    if (mounted) context.go('/');
  }

  Future<void> _runSync() async {
    setState(() {
      _running = true;
      _error = null;
      _syncProgress = null;
    });

    try {
      final outcome = await runMasterSyncWithIconPreload(
        ref,
        preloadOnlyMissingIcons: true,
        onProgress: (p) {
          if (mounted) setState(() => _syncProgress = p);
        },
      );
      final result = outcome.result;

      if (!mounted) return;

      if (result.characters == 0) {
        if (result.hasErrors) {
          logAppError(result.errors.join('; '), null, 'initialSync');
        }
        setState(() {
          _error = result.hasErrors
              ? userFacingSyncErrors(result.errors)
              : 'キャラデータを取得できませんでした。ネットワーク接続を確認してください。';
        });
        return;
      }

      context.go('/');
    } catch (e, st) {
      logAppError(e, st, 'initialSync');
      if (mounted) {
        setState(() =>
            _error = '同期に失敗しました。ネットワーク接続を確認して再試行してください。');
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
                'データ同期',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _subtitle ??
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
                  onPressed: _running ? null : _runSync,
                  child: const Text('再試行'),
                ),
                TextButton(
                  onPressed: _running ? null : () => context.go('/'),
                  child: const Text('スキップして続行'),
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
