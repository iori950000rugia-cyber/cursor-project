import '../data/models/master_models.dart';
import '../data/hoyolab/models/game_record.dart';
import '../data/hoyolab/owned_characters_result.dart';

/// キャラクター一覧の並び替えモード
enum CharacterListSortMode {
  ownedDefault,
  nameAsc,
  nameDesc,
  rarityDesc,
  rarityAsc,
  element,
  region,
  levelDesc,
  levelAsc,
  obtainedDesc,
  obtainedAsc,
  constellationDesc,
  friendshipDesc,
}

extension CharacterListSortModeLabels on CharacterListSortMode {
  String get label => switch (this) {
        CharacterListSortMode.ownedDefault => '所持優先（取得推定順）',
        CharacterListSortMode.nameAsc => '名前（あ→ん）',
        CharacterListSortMode.nameDesc => '名前（ん→あ）',
        CharacterListSortMode.rarityDesc => 'レアリティ（高い順）',
        CharacterListSortMode.rarityAsc => 'レアリティ（低い順）',
        CharacterListSortMode.element => '元素',
        CharacterListSortMode.region => '地域',
        CharacterListSortMode.levelDesc => 'レベル（高い順）',
        CharacterListSortMode.levelAsc => 'レベル（低い順）',
        CharacterListSortMode.obtainedDesc => '取得推定（新しい順）',
        CharacterListSortMode.obtainedAsc => '取得推定（古い順）',
        CharacterListSortMode.constellationDesc => '命ノ星座（多い順）',
        CharacterListSortMode.friendshipDesc => '好感度（高い順）',
      };

  static CharacterListSortMode fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return CharacterListSortMode.ownedDefault;
    return CharacterListSortMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => CharacterListSortMode.ownedDefault,
    );
  }
}

class CharacterListSortSettings {
  const CharacterListSortSettings({
    this.mode = CharacterListSortMode.ownedDefault,
    this.groupByOwnership = true,
  });

  final CharacterListSortMode mode;
  final bool groupByOwnership;

  CharacterListSortSettings copyWith({
    CharacterListSortMode? mode,
    bool? groupByOwnership,
  }) =>
      CharacterListSortSettings(
        mode: mode ?? this.mode,
        groupByOwnership: groupByOwnership ?? this.groupByOwnership,
      );

  static const storageKeyMode = 'character_list_sort_mode';
  static const storageKeyGroup = 'character_list_group_by_owned';
}

class CharacterListEntry {
  const CharacterListEntry({
    required this.character,
    required this.isOwned,
    this.owned,
  });

  final MasterCharacter character;
  final bool isOwned;
  final HoyolabOwnedCharacter? owned;
}

const _elementOrder = [
  'pyro',
  'hydro',
  'anemo',
  'electro',
  'dendro',
  'cryo',
  'geo',
];

List<CharacterListEntry> buildCharacterListEntries({
  required List<MasterCharacter> characters,
  required Map<String, HoyolabOwnedCharacter> ownedMap,
  CharacterListSortSettings settings = const CharacterListSortSettings(),
}) {
  final entries = characters
      .map((character) {
        final ownedInfo = lookupOwnedCharacter(ownedMap, character.id);
        return CharacterListEntry(
          character: character,
          isOwned: ownedInfo != null,
          owned: ownedInfo,
        );
      })
      .toList(growable: false);

  if (settings.groupByOwnership &&
      settings.mode == CharacterListSortMode.ownedDefault) {
    return _buildOwnedDefaultSplit(entries);
  }

  if (settings.groupByOwnership) {
    final owned = entries.where((entry) => entry.isOwned).toList();
    final unowned = entries.where((entry) => !entry.isOwned).toList();
    owned.sort((a, b) => _compareEntries(a, b, settings.mode));
    unowned.sort((a, b) => _compareEntries(a, b, settings.mode));
    return [...owned, ...unowned];
  }

  final sorted = [...entries]..sort((a, b) => _compareEntries(a, b, settings.mode));
  return sorted;
}

List<CharacterListEntry> _buildOwnedDefaultSplit(
  List<CharacterListEntry> entries,
) {
  final owned = entries.where((entry) => entry.isOwned).toList()
    ..sort(_compareOwnedDefault);
  final unowned = entries.where((entry) => !entry.isOwned).toList()
    ..sort((a, b) => a.character.name.compareTo(b.character.name));
  return [...owned, ...unowned];
}

int _compareEntries(
  CharacterListEntry a,
  CharacterListEntry b,
  CharacterListSortMode mode,
) {
  switch (mode) {
    case CharacterListSortMode.ownedDefault:
      return _compareOwnedDefault(a, b);
    case CharacterListSortMode.nameAsc:
      return a.character.name.compareTo(b.character.name);
    case CharacterListSortMode.nameDesc:
      return b.character.name.compareTo(a.character.name);
    case CharacterListSortMode.rarityDesc:
      return _compareIntDesc(a.character.rarity, b.character.rarity) != 0
          ? _compareIntDesc(a.character.rarity, b.character.rarity)
          : a.character.name.compareTo(b.character.name);
    case CharacterListSortMode.rarityAsc:
      return _compareIntAsc(a.character.rarity, b.character.rarity) != 0
          ? _compareIntAsc(a.character.rarity, b.character.rarity)
          : a.character.name.compareTo(b.character.name);
    case CharacterListSortMode.element:
      return _compareElement(a, b);
    case CharacterListSortMode.region:
      final regionCmp = a.character.region.compareTo(b.character.region);
      return regionCmp != 0
          ? regionCmp
          : a.character.name.compareTo(b.character.name);
    case CharacterListSortMode.levelDesc:
      return _compareOwnedIntDesc(
        a,
        b,
        (owned) => owned.level,
        tieBreaker: a.character.name.compareTo(b.character.name),
      );
    case CharacterListSortMode.levelAsc:
      return _compareOwnedIntAsc(
        a,
        b,
        (owned) => owned.level,
        tieBreaker: a.character.name.compareTo(b.character.name),
      );
    case CharacterListSortMode.obtainedDesc:
      return _compareObtainedDesc(a, b);
    case CharacterListSortMode.obtainedAsc:
      return _compareObtainedAsc(a, b);
    case CharacterListSortMode.constellationDesc:
      return _compareOwnedIntDesc(
        a,
        b,
        (owned) => owned.constellation,
        tieBreaker: a.character.name.compareTo(b.character.name),
      );
    case CharacterListSortMode.friendshipDesc:
      return _compareOwnedIntDesc(
        a,
        b,
        (owned) => owned.friendship,
        tieBreaker: a.character.name.compareTo(b.character.name),
      );
  }
}

int _compareOwnedDefault(CharacterListEntry a, CharacterListEntry b) {
  final oa = a.owned!;
  final ob = b.owned!;

  final dateCmp = _compareObtainedDateDesc(oa.obtainedAt, ob.obtainedAt);
  if (dateCmp != 0) return dateCmp;

  final levelCmp = ob.level.compareTo(oa.level);
  if (levelCmp != 0) return levelCmp;

  return a.character.name.compareTo(b.character.name);
}

int _compareObtainedDateDesc(DateTime? aDate, DateTime? bDate) {
  if (aDate != null && bDate != null) {
    return bDate.compareTo(aDate);
  }
  if (aDate != null) return -1;
  if (bDate != null) return 1;
  return 0;
}

int _compareObtainedDateAsc(DateTime? aDate, DateTime? bDate) {
  if (aDate != null && bDate != null) {
    return aDate.compareTo(bDate);
  }
  if (aDate != null) return -1;
  if (bDate != null) return 1;
  return 0;
}

int _compareElement(CharacterListEntry a, CharacterListEntry b) {
  final aIndex = _elementOrder.indexOf(a.character.element);
  final bIndex = _elementOrder.indexOf(b.character.element);
  final safeA = aIndex >= 0 ? aIndex : _elementOrder.length;
  final safeB = bIndex >= 0 ? bIndex : _elementOrder.length;
  final cmp = safeA.compareTo(safeB);
  return cmp != 0 ? cmp : a.character.name.compareTo(b.character.name);
}

int _compareObtainedDesc(CharacterListEntry a, CharacterListEntry b) {
  final ownedCmp = _compareOwnedFirst(a, b);
  if (ownedCmp != 0) return ownedCmp;

  final dateCmp =
      _compareObtainedDateDesc(a.owned?.obtainedAt, b.owned?.obtainedAt);
  if (dateCmp != 0) return dateCmp;

  return a.character.name.compareTo(b.character.name);
}

int _compareObtainedAsc(CharacterListEntry a, CharacterListEntry b) {
  final ownedCmp = _compareOwnedFirst(a, b);
  if (ownedCmp != 0) return ownedCmp;

  final dateCmp =
      _compareObtainedDateAsc(a.owned?.obtainedAt, b.owned?.obtainedAt);
  if (dateCmp != 0) return dateCmp;

  return a.character.name.compareTo(b.character.name);
}

int _compareOwnedFirst(CharacterListEntry a, CharacterListEntry b) {
  if (a.isOwned && !b.isOwned) return -1;
  if (!a.isOwned && b.isOwned) return 1;
  return 0;
}

int _compareOwnedIntDesc(
  CharacterListEntry a,
  CharacterListEntry b,
  int Function(HoyolabOwnedCharacter owned) selector, {
  required int tieBreaker,
}) {
  final ownedCmp = _compareOwnedFirst(a, b);
  if (ownedCmp != 0) return ownedCmp;

  final aValue = a.owned == null ? -1 : selector(a.owned!);
  final bValue = b.owned == null ? -1 : selector(b.owned!);
  final cmp = bValue.compareTo(aValue);
  return cmp != 0 ? cmp : tieBreaker;
}

int _compareOwnedIntAsc(
  CharacterListEntry a,
  CharacterListEntry b,
  int Function(HoyolabOwnedCharacter owned) selector, {
  required int tieBreaker,
}) {
  final ownedCmp = _compareOwnedFirst(a, b);
  if (ownedCmp != 0) return ownedCmp;

  final aValue = a.owned == null ? 999 : selector(a.owned!);
  final bValue = b.owned == null ? 999 : selector(b.owned!);
  final cmp = aValue.compareTo(bValue);
  return cmp != 0 ? cmp : tieBreaker;
}

int _compareIntDesc(int a, int b) => b.compareTo(a);

int _compareIntAsc(int a, int b) => a.compareTo(b);

/// セクション表示用: 所持/未所持の境界インデックス（groupByOwnership=true のとき）
int ownedEntryCount(List<CharacterListEntry> entries) =>
    entries.where((entry) => entry.isOwned).length;

bool shouldShowOwnershipSections(CharacterListSortSettings settings) {
  if (!settings.groupByOwnership) return false;
  return true;
}
