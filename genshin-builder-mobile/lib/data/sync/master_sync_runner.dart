import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/daily_materials_providers.dart';
import '../models/sync_status.dart';
import 'icon_preload_service.dart';
import 'master_sync_service.dart';

/// マスタ同期のあとアイコンをディスクキャッシュへ事前取得
Future<({SyncResult result, int iconsLoaded})> runMasterSyncWithIconPreload(
  WidgetRef ref, {
  void Function(SyncProgress progress)? onProgress,
  bool preloadOnlyMissingIcons = false,
  bool fullUpgrade = false,
}) async {
  final db = await ref.read(appDatabaseProvider.future);
  final amber = ref.read(amberApiProvider);
  final service = MasterSyncService(
    amberApi: amber,
    db: db,
    fullUpgrade: fullUpgrade,
  );
  final result = await service.syncMasterData(onProgress: onProgress);

  onProgress?.call(
    const SyncProgress(
      phase: SyncPhase.iconPreload,
      current: 0,
      total: 0,
      detail: '準備中',
    ),
  );

  final iconsLoaded = await IconPreloadService(db).preloadMasterIcons(
    onlyMissing: preloadOnlyMissingIcons,
    onProgress: onProgress,
  );

  // 新キャラが追加された場合、重み未登録を検知してリモート再取得を試みる。
  final weightRepo = ref.read(artifactScoreWeightRepositoryProvider);
  final characters = await db.getAllCharacters();
  final missingWeightIds =
      await weightRepo.syncMissingCharacterProfiles(characters);
  if (missingWeightIds.isNotEmpty) {
    await db.insertSyncLog(
      'partial',
      'artifact score weights missing for: ${missingWeightIds.join(',')}',
    );
  }

  // 同期結果と重みデータを基にバージョンを自動更新
  final versioning = await ref.read(versioningServiceProvider.future);
  await versioning.updateAndPersistVersions();

  invalidateMasterDataProviders(ref);
  invalidateDailyMaterialsProviders(ref);
  return (result: result, iconsLoaded: iconsLoaded);
}
