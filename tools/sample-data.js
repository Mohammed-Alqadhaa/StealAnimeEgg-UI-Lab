// ============================================================================
//  SAMPLE / PREVIEW DATA ONLY – NOT PRODUCTION GAMEPLAY, NOT A GAME ECONOMY.
//  Every number and price below is a placeholder used to populate the UI lab.
//  It is emitted to src/client/PREVIEW_SampleData.lua by build.js.
// ============================================================================
module.exports = {
  __NOTICE: 'SAMPLE DATA ONLY - NOT PRODUCTION GAMEPLAY OR ECONOMY',
  hatchSeconds: 60, // development timer for preview/testing only

  hud: { speed: '1.7M', cash: '$5.6T', income: '+$216/s' },

  characters: {
    tanjiro:  { name: 'Tanjiro',  rarity: 'Rare',      art: 'char_tanjiro',  chance: '40%' },
    akaza:    { name: 'Akaza',    rarity: 'Epic',      art: 'char_akaza',    chance: '30%' },
    rengoku:  { name: 'Rengoku',  rarity: 'Legendary', art: 'char_rengoku',  chance: '20%' },
    muzan:    { name: 'Muzan',    rarity: 'Mythic',    art: 'char_muzan',    chance: '9%' },
    yoriichi: { name: 'Yoriichi', rarity: 'Secret',    art: 'char_yoriichi', chance: '1%' },
  },

  index: {
    series: 'Demon Slayer',
    order: ['rengoku', 'yoriichi', 'muzan', 'akaza', 'tanjiro'],
    discovered: ['rengoku', 'akaza', 'tanjiro'],
  },

  // Separate duplicate units (Rengoku Unit 1 / Unit 2 ...)
  equipSlots: 4,
  units: [
    { id: 'rengoku_1',  char: 'rengoku',  unit: 1, level: 7,  income: 96,  equipped: true },
    { id: 'rengoku_2',  char: 'rengoku',  unit: 2, level: 2,  income: 54,  equipped: false },
    { id: 'yoriichi_1', char: 'yoriichi', unit: 1, level: 1,  income: 120, equipped: false },
    { id: 'muzan_1',    char: 'muzan',    unit: 1, level: 3,  income: 88,  equipped: true },
    { id: 'akaza_1',    char: 'akaza',    unit: 1, level: 10, income: 64,  equipped: true },
    { id: 'tanjiro_1',  char: 'tanjiro',  unit: 1, level: 5,  income: 22,  equipped: false },
    { id: 'tanjiro_2',  char: 'tanjiro',  unit: 2, level: 1,  income: 12,  equipped: false },
    { id: 'akaza_2',    char: 'akaza',    unit: 2, level: 4,  income: 40,  equipped: false },
  ],

  eggs: [
    { id: 'egg_1', name: 'Demon Slayer Egg', art: 'egg_demon',  rarity: 'Epic',      state: 'OWNED',    count: 2,     result: 'akaza' },
    { id: 'egg_2', name: 'Anime Egg',        art: 'egg_anime',  rarity: 'Mythic',    state: 'HATCHING', remaining: 42, result: 'muzan' },
    { id: 'egg_3', name: 'Flame Egg',        art: 'egg_flame',  rarity: 'Legendary', state: 'READY',                  result: 'yoriichi' },
    { id: 'egg_4', name: 'Moon Egg',         art: 'egg_moon',   rarity: 'Rare',      state: 'OPENED',   result: 'rengoku' },
  ],
  eggStorage: { used: 4, max: 8 },

  upgrade: {
    maxLevel: 10,
    characters: [
      { unit: 'rengoku_1', level: 7,  income: 96,  next: 118, cost: '$1.2K' },
      { unit: 'akaza_1',   level: 10, income: 64,  next: null, cost: null },
      { unit: 'muzan_1',   level: 3,  income: 88,  next: 104, cost: '$640' },
      { unit: 'tanjiro_1', level: 5,  income: 22,  next: 27,  cost: '$139' },
    ],
    treadmill: { level: 4, max: 10, gain: '+12', next: '+16', cost: '$25K' },
    farm: { level: 3, max: 8, slots: 4, nextSlots: 5, cost: '$150K' },
  },

  // Sample prices (premium currency amounts are placeholders)
  shop: {
    featured: { name: 'ANIME EGG', prices: [{ n: '1 Egg', p: '49' }, { n: '3 Eggs', p: '124' }, { n: '10 Eggs', p: '399', best: true }] },
    starter: { price: '99', was: '329', contents: ['$50K', 'x2 Speed', '1 Egg'] },
    vip: { price: '499', perks: ['+25% Cash', 'VIP Chat Tag', 'Gold Name'] },
    cash: [
      { amt: '$10K', p: '25', icon: 'icon_coin' }, { amt: '$150K', p: '99', icon: 'icon_cash' },
      { amt: '$2.5M', p: '399', icon: 'icon_moneybag' }, { amt: '$50M', p: '999', icon: 'icon_moneybag', best: true },
    ],
    boosts: [
      { name: 'x2 Cash', time: '15 MIN', p: '39', icon: 'icon_potion', theme: 'cash' },
      { name: 'x2 Speed', time: '15 MIN', p: '39', icon: 'icon_bolt', theme: 'speed' },
      { name: 'Luck', time: '10 MIN', p: '59', icon: 'icon_clover', theme: 'upgrade' },
      { name: 'Fast Hatch', time: '30 MIN', p: '79', icon: 'icon_hourglass', theme: 'eggs' },
    ],
    special: [
      { name: 'SPEED PACK', desc: '+500K Speed', p: '149', icon: 'icon_speed', theme: 'speed' },
      { name: 'EGG BUNDLE', desc: '5 Mixed Eggs', p: '249', icon: 'icon_eggs', theme: 'eggs' },
    ],
  },
};
