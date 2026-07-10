/// UI 表示用ラベル・色（features は data/amber ではなくここを参照する）
library;

const elementLabelMap = <String, String>{
  'pyro': '炎',
  'hydro': '水',
  'electro': '雷',
  'cryo': '氷',
  'anemo': '風',
  'geo': '岩',
  'dendro': '草',
};

const weaponTypeLabelMap = <String, String>{
  'sword': '片手剣',
  'claymore': '両手剣',
  'polearm': '長柄武器',
  'bow': '弓',
  'catalyst': '法器',
};

/// 元素バッジ用カラー（Web `ELEMENT_INFO` 相当）
const elementColorMap = <String, int>{
  'pyro': 0xFFFF6B4A,
  'hydro': 0xFF4FC3F7,
  'electro': 0xFFB388FF,
  'cryo': 0xFF80DEEA,
  'anemo': 0xFF69F0AE,
  'geo': 0xFFFFD54F,
  'dendro': 0xFFA5D6A7,
};
