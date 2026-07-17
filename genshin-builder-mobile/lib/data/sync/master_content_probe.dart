import '../amber/amber_api.dart';
import '../db/app_database.dart';

/// Amber 一覧とローカル DB を比較し、新コンテンツ同期が必要か判定する。
class MasterContentProbe {
  MasterContentProbe({required AmberApi amberApi, required AppDatabase db})
    : _amber = amberApi,
      _db = db;

  final AmberApi _amber;
  final AppDatabase _db;

  /// リモート一覧件数とローカル件数を比較する（突破詳細は取得しない）。
  Future<MasterContentProbeResult> check() async {
    try {
      final remote = await _amber.fetchMasterListCounts();
      final local = await _db.getMasterContentCounts();
      final localChars = local.characters;
      final localWeapons = local.weapons;
      final localMaterials = local.materials;
      final syncedCharUp = local.characterUpgrades;
      final syncedWpnUp = local.weaponUpgrades;

      final reasons = <String>[];
      if (remote.characters > localChars) {
        reasons.add('新キャラ ${remote.characters - localChars} 件');
      }
      if (remote.weapons > localWeapons) {
        reasons.add('新武器 ${remote.weapons - localWeapons} 件');
      }
      if (remote.materials > localMaterials) {
        reasons.add('新素材 ${remote.materials - localMaterials} 件');
      }
      if (localChars > syncedCharUp) {
        reasons.add('未取得のキャラ突破 ${localChars - syncedCharUp} 件');
      }
      if (localWeapons > syncedWpnUp) {
        reasons.add('未取得の武器突破 ${localWeapons - syncedWpnUp} 件');
      }

      return MasterContentProbeResult(
        shouldSync: reasons.isNotEmpty,
        reasons: reasons,
        remoteCharacters: remote.characters,
        remoteWeapons: remote.weapons,
        remoteMaterials: remote.materials,
        localCharacters: localChars,
        localWeapons: localWeapons,
        localMaterials: localMaterials,
      );
    } catch (e) {
      // プローブ失敗時は起動を止めない（手動同期に委ねる）
      return MasterContentProbeResult(
        shouldSync: false,
        reasons: const [],
        error: '$e',
      );
    }
  }
}

class MasterContentProbeResult {
  const MasterContentProbeResult({
    required this.shouldSync,
    required this.reasons,
    this.remoteCharacters = 0,
    this.remoteWeapons = 0,
    this.remoteMaterials = 0,
    this.localCharacters = 0,
    this.localWeapons = 0,
    this.localMaterials = 0,
    this.error,
  });

  final bool shouldSync;
  final List<String> reasons;
  final int remoteCharacters;
  final int remoteWeapons;
  final int remoteMaterials;
  final int localCharacters;
  final int localWeapons;
  final int localMaterials;
  final String? error;

  String get reasonSummary => reasons.isEmpty ? '' : reasons.join(' · ');
}
