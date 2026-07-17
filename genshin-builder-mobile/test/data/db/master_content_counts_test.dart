import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/data/db/app_database.dart';
import 'package:genshin_builder_mobile/data/models/master_models.dart';

void main() {
  test(
    'master content counts reflect rows without loading full models',
    () async {
      final db = await AppDatabase.openInMemory();
      addTearDown(db.close);

      await db.upsertCharacter(
        const MasterCharacter(
          id: 'character-1',
          name: 'Character',
          element: 'anemo',
          weaponType: 'sword',
          rarity: 5,
          region: 'mondstadt',
          iconUrl: '',
        ),
      );
      await db.upsertWeapon(
        const MasterWeapon(
          id: 'weapon-1',
          name: 'Weapon',
          weaponType: 'sword',
          rarity: 5,
          iconUrl: '',
        ),
      );
      await db.upsertMaterial(
        const MasterMaterial(
          id: 'material-1',
          name: 'Material',
          category: 'test',
          iconUrl: '',
        ),
      );
      await db.upsertCharacterUpgrade(
        characterId: 'character-1',
        promotes: const [],
        talents: const {},
      );
      await db.upsertWeaponUpgrade(
        weaponId: 'weapon-1',
        promotes: const [],
        levelUpItemIds: const [],
      );

      final counts = await db.getMasterContentCounts();
      expect(counts.characters, 1);
      expect(counts.weapons, 1);
      expect(counts.materials, 1);
      expect(counts.characterUpgrades, 1);
      expect(counts.weaponUpgrades, 1);

      final status = await db.getSyncStatus();
      expect(status.characters, 1);
      expect(status.weapons, 1);
      expect(status.materials, 1);
      expect(status.characterUpgrades, 1);
      expect(status.weaponUpgrades, 1);
    },
  );
}
