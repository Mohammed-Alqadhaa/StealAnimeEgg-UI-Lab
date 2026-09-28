// Design tokens – mirrored in src/client/Theme.lua and docs/DESIGN_SYSTEM.md
const INK = '#1B1036';

// Each swatch: hi (top light), base, lo (bottom saturated), lip (3D edge), body (menu interior)
const C = {
  shop:    { hi: '#FFA3BE', base: '#FF4F7E', lo: '#D81B5A', lip: '#8E0E3A', body: '#FFE9F0', text: '#C2185B' },
  index:   { hi: '#A8ECFF', base: '#35A2FF', lo: '#1B63D6', lip: '#0F3E9E', body: '#E4F4FF', text: '#1565C0' },
  eggs:    { hi: '#FFF3A6', base: '#FFC21F', lo: '#FF8A00', lip: '#A85200', body: '#FFF5DC', text: '#C25E00' },
  chars:   { hi: '#DCC2FF', base: '#9A5CFF', lo: '#6A2FE0', lip: '#3E1A99', body: '#F1E9FF', text: '#5B2BC4' },
  upgrade: { hi: '#D2FF96', base: '#5CE63C', lo: '#1DA53C', lip: '#0B6B22', body: '#EAFFE2', text: '#15803D' },
  speed:   { hi: '#A6F2FF', base: '#35B8FF', lo: '#1E7BFF', lip: '#0F4AA8', body: '#E4F6FF', text: '#0D5BD6' },
  cash:    { hi: '#C2FFA3', base: '#46D95F', lo: '#1E9F3E', lip: '#0E5E24', body: '#E8FFE8', text: '#15803D' },
  red:     { hi: '#FFA597', base: '#FF4D4D', lo: '#D81B2E', lip: '#7A0A18', body: '#FFE8E8', text: '#B71C1C' },
  gold:    { hi: '#FFF7B0', base: '#FFD23F', lo: '#FFA000', lip: '#A85F00', body: '#FFF8DC', text: '#B36B00' },
  slate:   { hi: '#A7AFD6', base: '#6E76A0', lo: '#4A5078', lip: '#262A45', body: '#E9EBF5', text: '#3A3F63' },
  white:   { hi: '#FFFFFF', base: '#F4F6FF', lo: '#D3DAF3', lip: '#8C95BF', body: '#FFFFFF', text: '#1B1036' },
  night:   { hi: '#6B4DD6', base: '#3A2A8F', lo: '#1F155A', lip: '#0E0930', body: '#2A1F66', text: '#FFFFFF' },
};

const RARITY = {
  Common:    { ...C.slate, label: 'COMMON' },
  Rare:      { ...C.index, label: 'RARE' },
  Epic:      { ...C.chars, label: 'EPIC' },
  Legendary: { ...C.gold, label: 'LEGENDARY' },
  Mythic:    { ...C.red, hi: '#FF9AD5', base: '#FF3D8B', lo: '#C2126B', lip: '#6E0A3C', label: 'MYTHIC' },
  Secret:    { ...C.night, label: 'SECRET', rainbow: ['#FF4F7E', '#FFD23F', '#46D95F', '#35B8FF', '#9A5CFF'] },
};

module.exports = { INK, C, RARITY, BASE_RES: [1280, 720] };
