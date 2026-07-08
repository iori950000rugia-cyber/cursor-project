import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/character_list_sort.dart';
import 'app_providers.dart';

final characterListSortSettingsProvider =
    AsyncNotifierProvider<CharacterListSortSettingsNotifier,
        CharacterListSortSettings>(
  CharacterListSortSettingsNotifier.new,
);

class CharacterListSortSettingsNotifier
    extends AsyncNotifier<CharacterListSortSettings> {
  @override
  Future<CharacterListSortSettings> build() async {
    final db = await ref.watch(appDatabaseProvider.future);
    final modeRaw = await db.getSetting(CharacterListSortSettings.storageKeyMode);
    final groupRaw =
        await db.getSetting(CharacterListSortSettings.storageKeyGroup);
    return CharacterListSortSettings(
      mode: CharacterListSortModeLabels.fromStorage(modeRaw),
      groupByOwnership: groupRaw != 'false',
    );
  }

  Future<void> updateSettings(CharacterListSortSettings settings) async {
    state = AsyncData(settings);
    final db = await ref.read(appDatabaseProvider.future);
    await db.setSetting(
      CharacterListSortSettings.storageKeyMode,
      settings.mode.name,
    );
    await db.setSetting(
      CharacterListSortSettings.storageKeyGroup,
      settings.groupByOwnership.toString(),
    );
  }

  Future<void> setMode(CharacterListSortMode mode) async {
    final current = state.valueOrNull ?? const CharacterListSortSettings();
    await updateSettings(current.copyWith(mode: mode));
  }

  Future<void> setGroupByOwnership(bool value) async {
    final current = state.valueOrNull ?? const CharacterListSortSettings();
    await updateSettings(current.copyWith(groupByOwnership: value));
  }
}
