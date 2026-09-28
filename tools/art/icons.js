// Original UI icon art for StealAnimeEgg-UI-Lab. 256x256 unless noted.
// Output: assets/svg/<name>.svg  (rendered to assets/png + atlases by render-art.js)
const { INK, icon, path, plain, tube, spark } = require('./kit');

const A = {};

// ---------------------------------------------------------------- NAV ICONS
A.icon_shop = () => {
  const k = icon();
  // handles
  k.add(tube('M88 100 Q88 34 128 34 Q168 34 168 100', '#FFF1C7', 14, 9));
  // bag
  k.add(path('M50 86 L206 86 L222 220 Q223 236 207 236 L49 236 Q33 236 34 220 Z', k.tone('#FF8FB0', '#D81B5A', '#FF4F7E'), 10));
  k.add(plain('M50 86 L206 86 L208 106 L48 106 Z', '#A80F45'));
  k.add(plain('M60 86 L196 86 L197 94 L59 94 Z', '#FFB3C9', 'opacity="0.7"'));
  k.gloss('M58 112 L80 112 L70 222 L48 222 Z', 0.8);
  // handle holes
  k.add(`<circle cx="88" cy="100" r="7" fill="${INK}"/><circle cx="168" cy="100" r="7" fill="${INK}"/>`);
  // star print
  k.add(path('M118 128 L126 146 L146 148 L131 161 L135 180 L118 170 L101 180 L105 161 L90 148 L110 146 Z', '#FFFFFF', 7));
  // coin
  k.add(`<circle cx="186" cy="192" r="46" fill="${k.tone('#FFF09A', '#FFA412', '#FFD23F')}" stroke="${INK}" stroke-width="10"/>`);
  k.add(`<circle cx="186" cy="192" r="32" fill="none" stroke="#E08600" stroke-width="6"/>`);
  k.add(tube('M200 176 Q186 166 174 174 Q166 184 182 191 Q200 198 192 210 Q180 220 168 210', '#FFFFFF', 7, 5));
  k.add(tube('M184 160 L184 224', '#FFFFFF', 6, 5));
  k.gloss('M152 172 Q160 152 182 150 Q168 160 164 176 Z', 0.9);
  k.add(spark(40, 52, 1.4), spark(222, 58, 1));
  return k.done();
};

A.icon_index = () => {
  const k = icon();
  // page block
  k.add(path('M70 40 L206 40 Q220 40 220 54 L220 214 Q220 228 206 228 L70 228 Z', '#FFF6DA', 10));
  k.add(plain('M78 214 L210 214 L210 220 L78 220 Z', '#E9D9A8'), plain('M78 200 L210 200 L210 205 L78 205 Z', '#E9D9A8'));
  // cover
  k.add(path('M38 32 L190 32 Q204 32 204 46 L204 200 Q204 214 190 214 L38 214 Q30 214 30 206 L30 40 Q30 32 38 32 Z', k.tone('#6FD8FF', '#1B63D6', '#35A2FF'), 10));
  // spine band
  k.add(plain('M34 36 L62 36 L62 210 L34 210 Z', '#1650B8', 'opacity="0.9"'));
  k.add(plain('M62 36 L68 36 L68 210 L62 210 Z', '#9BE6FF', 'opacity="0.8"'));
  // emblem ring + star
  k.add(`<circle cx="134" cy="118" r="50" fill="#0F3E9E" stroke="${INK}" stroke-width="8"/>`);
  k.add(`<circle cx="134" cy="118" r="40" fill="none" stroke="#FFD23F" stroke-width="6" stroke-dasharray="10 8"/>`);
  k.add(path('M134 80 L145 105 L172 107 L151 124 L158 150 L134 136 L110 150 L117 124 L96 107 L123 105 Z', k.tone('#FFF6A8', '#FFB400'), 7));
  // gold corners
  k.add(path('M204 32 L204 70 L170 32 Z', '#FFD23F', 7), path('M204 214 L204 176 L170 214 Z', '#FFD23F', 7));
  // bookmark ribbon
  k.add(path('M150 206 L150 246 L164 234 L178 246 L178 206 Z', k.tone('#FF6B6B', '#C9163A'), 8));
  k.gloss('M70 42 L186 42 Q192 42 190 50 L186 62 L70 62 Z', 0.6);
  k.add(spark(226, 30, 1.2));
  return k.done();
};

A.icon_eggs = () => {
  const k = icon();
  const egg = 'M128 18 C182 18 218 100 218 152 C218 206 178 238 128 238 C78 238 38 206 38 152 C38 100 74 18 128 18 Z';
  k.def(`<clipPath id="eggclip"><path d="${egg}"/></clipPath>`);
  k.add(path(egg, k.tone('#FFFBE6', '#FFB52E', '#FFE27A'), 11));
  k.add(`<g clip-path="url(#eggclip)">` +
    `<path d="M30 150 L62 128 L94 150 L126 128 L158 150 L190 128 L222 150 L222 178 L190 156 L158 178 L126 156 L94 178 L62 156 L30 178 Z" fill="#FF7A1A" stroke="${INK}" stroke-width="6" stroke-linejoin="round"/>` +
    `<circle cx="92" cy="92" r="13" fill="#FF9F3D"/><circle cx="162" cy="70" r="9" fill="#FF9F3D"/><circle cx="170" cy="112" r="14" fill="#FF9F3D"/>` +
    `<circle cx="96" cy="210" r="12" fill="#FF9F3D"/><circle cx="160" cy="206" r="16" fill="#FF9F3D"/>` +
    `<path d="M38 150 C38 206 78 238 128 238 C178 238 218 206 218 152 L218 238 L38 238 Z" fill="#C45A00" opacity="0.18"/>` +
    `</g>`);
  k.gloss('M86 44 Q104 30 118 38 Q96 60 88 96 Q74 80 86 44 Z', 0.95);
  k.add(spark(214, 40, 1.3), spark(40, 214, 0.9));
  return k.done();
};

A.icon_characters = () => {
  const k = icon();
  // back card
  k.add(`<g transform="rotate(-14 128 128)">` + path('M46 40 L166 40 Q180 40 180 54 L180 206 Q180 220 166 220 L46 220 Q32 220 32 206 L32 54 Q32 40 46 40 Z', k.tone('#FF8FD8', '#C23BD6'), 10) + `</g>`);
  // front card
  k.add(`<g transform="rotate(8 150 140)">` +
    path('M90 36 L210 36 Q226 36 226 52 L226 218 Q226 234 210 234 L90 234 Q74 234 74 218 L74 52 Q74 36 90 36 Z', k.tone('#C9A2FF', '#6A2FE0', '#9A5CFF'), 10) +
    `<path d="M86 48 L214 48 L214 150 L86 150 Z" fill="${k.rad([[0, '#FFFFFF', 0.55], [1, '#FFFFFF', 0]], { cy: 0.7, r: 0.7 })}"/>` +
    // chibi bust
    path('M110 234 Q112 194 150 190 Q188 194 190 234 Z', '#2B2356', 8) +
    path('M150 190 L136 200 L150 222 L164 200 Z', '#FFFFFF', 5) +
    path('M118 126 Q118 84 150 84 Q182 84 182 126 Q180 172 150 180 Q120 172 118 126 Z', '#FFE3CF', 8) +
    // spiky hair
    path('M108 124 L102 100 L116 104 L112 80 L130 90 L134 66 L150 82 L164 64 L170 88 L188 80 L184 104 L198 100 L190 126 Q180 104 170 100 L160 112 L150 98 L138 112 L128 100 Q118 106 108 124 Z', k.tone('#6B4DFF', '#271A6B'), 8) +
    `<ellipse cx="136" cy="136" rx="7" ry="10" fill="${INK}"/><ellipse cx="164" cy="136" rx="7" ry="10" fill="${INK}"/>` +
    `<circle cx="138" cy="132" r="3" fill="#FFF"/><circle cx="166" cy="132" r="3" fill="#FFF"/>` +
    `<path d="M142 158 Q150 164 158 158" fill="none" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>` +
    `<ellipse cx="128" cy="152" rx="7" ry="4" fill="#FF8FA8" opacity="0.7"/><ellipse cx="172" cy="152" rx="7" ry="4" fill="#FF8FA8" opacity="0.7"/>` +
    `</g>`);
  // star badge
  k.add(path('M208 176 L218 198 L242 200 L224 216 L230 240 L208 227 L186 240 L192 216 L174 200 L198 198 Z', k.tone('#FFF6A8', '#FFB400'), 8));
  k.add(spark(40, 30, 1.2));
  return k.done();
};

A.icon_upgrade = () => {
  const k = icon();
  const arrow = 'M128 20 L224 116 Q230 124 220 124 L170 124 L170 216 Q170 234 152 234 L104 234 Q86 234 86 216 L86 124 L36 124 Q26 124 32 116 Z';
  k.add(path(arrow, k.tone('#D8FF8A', '#17A52E', '#5CE63C'), 11));
  k.add(plain('M128 34 L206 112 L166 112 L166 124 L220 124 L128 32 Z', '#FFFFFF', 'opacity="0.0"'));
  k.gloss('M128 34 L60 106 Q56 112 64 112 L98 112 L98 220 Q98 224 102 224 L112 224 L112 104 L128 44 Z', 0.85);
  k.add(plain('M170 124 L170 216 Q170 234 152 234 L140 234 Q156 230 156 214 L156 124 Z', '#0B7A22', 'opacity="0.5"'));
  // chevrons
  k.add(tube('M104 196 L128 172 L152 196', '#FFFFFF', 10, 0), tube('M104 164 L128 140 L152 164', '#FFFFFF', 10, 0, 'opacity="0.75"'));
  k.add(spark(44, 188, 1.3, '#FFF6A8'), spark(214, 190, 1.1), spark(214, 44, 0.9, '#FFF6A8'));
  return k.done();
};

// ------------------------------------------------------------ HUD CURRENCIES
// Original speed emblem: a sprinting figure bursting out of motion streaks.
A.icon_speed = () => {
  const k = icon();
  // motion streaks
  k.add(tube('M20 112 L78 112', '#7FE6FF', 12, 8), tube('M34 146 L96 146', '#35B8FF', 14, 8), tube('M20 180 L70 180', '#7FE6FF', 12, 8));
  // lightning accent behind
  k.add(path('M188 22 L150 96 L178 96 L146 160 L214 80 L184 80 L208 22 Z', k.tone('#FFF59A', '#FFB300'), 8));
  const B = '#1E90FF';
  // back arm + back leg (darker, behind)
  k.add(tube('M148 102 L118 116 L96 100', '#1466D6', 22, 9));
  k.add(tube('M130 158 L108 198 L70 178', '#1466D6', 24, 9));
  // torso
  k.add(tube('M156 96 L132 156', B, 34, 9));
  // front leg (knee drive)
  k.add(tube('M132 158 L178 168 L168 218', B, 26, 9));
  k.add(path('M152 210 L184 210 Q196 212 194 224 L150 226 Q144 218 152 210 Z', '#FFFFFF', 8));
  k.add(path('M58 158 Q70 156 76 166 L70 188 L50 180 Q48 166 58 158 Z', '#E6F4FF', 8));
  // front arm
  k.add(tube('M154 104 L186 126 L212 108', B, 22, 9));
  // head
  k.add(`<circle cx="176" cy="60" r="28" fill="${k.tone('#8FE3FF', '#1E90FF')}" stroke="${INK}" stroke-width="9"/>`);
  // highlights on limbs
  k.add(`<path d="M154 104 L140 138" stroke="#9EE8FF" stroke-width="8" stroke-linecap="round" opacity="0.9"/>`);
  k.add(`<path d="M140 162 L170 169" stroke="#9EE8FF" stroke-width="7" stroke-linecap="round" opacity="0.8"/>`);
  k.add(`<ellipse cx="166" cy="50" rx="10" ry="7" fill="#FFFFFF" opacity="0.85"/>`);
  k.add(spark(228, 150, 1.1), spark(110, 40, 0.9, '#BFF3FF'));
  return k.done();
};

A.icon_cash = () => {
  const k = icon();
  const bill = (dy, top, bot, emblem) => {
    let s = `<g transform="translate(0 ${dy})">` +
      path('M26 132 L170 88 Q180 86 184 94 L232 152 Q236 160 226 164 L84 208 Q74 210 70 202 L22 144 Q18 136 26 132 Z', k.tone(top, bot), 10);
    if (emblem) {
      s += `<path d="M48 142 L166 106 L208 156 L90 192 Z" fill="none" stroke="#0E7A34" stroke-width="5" stroke-linejoin="round" opacity="0.8"/>` +
        `<ellipse cx="128" cy="148" rx="30" ry="22" transform="rotate(-17 128 148)" fill="#C8FFB0" stroke="#0E7A34" stroke-width="5"/>` +
        `<path d="M136 136 Q126 132 118 138 Q114 146 126 148 Q138 150 134 158 Q128 164 118 160" fill="none" stroke="#0E7A34" stroke-width="6" stroke-linecap="round"/>`;
    }
    return s + '</g>';
  };
  k.add(bill(36, '#46C95F', '#177A33'), bill(18, '#5BDC70', '#1E8F3E'), bill(0, '#9CFF8E', '#2DB84E', true));
  k.gloss('M34 134 L166 94 L176 104 L48 144 Z', 0.8);
  // coin
  k.add(`<circle cx="190" cy="196" r="40" fill="${k.tone('#FFF09A', '#FFA412', '#FFD23F')}" stroke="${INK}" stroke-width="10"/>`);
  k.add(path('M190 172 L197 188 L214 189 L201 200 L205 217 L190 208 L175 217 L179 200 L166 189 L183 188 Z', '#FFFFFF', 0));
  k.add(`<path d="M190 172 L197 188 L214 189 L201 200 L205 217 L190 208 L175 217 L179 200 L166 189 L183 188 Z" fill="#FFF7C2" stroke="#D98300" stroke-width="4" stroke-linejoin="round"/>`);
  k.add(spark(40, 60, 1.3), spark(214, 44, 1));
  return k.done();
};

// Generic premium currency gem (sample – swap for the official Robux glyph in production).
A.icon_gem = () => {
  const k = icon();
  k.add(path('M128 236 L22 102 L68 34 L188 34 L234 102 Z', k.tone('#9FF7FF', '#1F8BFF', '#4FD2FF'), 11));
  k.add(plain('M68 34 L96 102 L128 236 L22 102 Z', '#FFFFFF', 'opacity="0.18"'));
  k.add(plain('M188 34 L160 102 L128 236 L234 102 Z', '#0A3FA8', 'opacity="0.25"'));
  k.add(plain('M68 34 L188 34 L160 102 L96 102 Z', '#FFFFFF', 'opacity="0.35"'));
  k.add(`<path d="M22 102 L234 102 M96 102 L128 236 L160 102 M96 102 L68 34 M160 102 L188 34" fill="none" stroke="${INK}" stroke-width="5" stroke-linejoin="round" opacity="0.55"/>`);
  k.add(spark(92, 64, 1.1), spark(210, 176, 0.9));
  return k.done();
};

A.icon_coin = () => {
  const k = icon();
  k.add(`<ellipse cx="128" cy="140" rx="100" ry="96" fill="#C77700" stroke="${INK}" stroke-width="11"/>`);
  k.add(`<circle cx="128" cy="126" r="96" fill="${k.tone('#FFF3A0', '#FFA800', '#FFD23F')}" stroke="${INK}" stroke-width="11"/>`);
  k.add(`<circle cx="128" cy="126" r="70" fill="none" stroke="#E08A00" stroke-width="8"/>`);
  k.add(`<path d="M128 78 L142 110 L176 112 L150 134 L158 168 L128 150 L98 168 L106 134 L80 112 L114 110 Z" fill="#FFF7C2" stroke="#D98300" stroke-width="6" stroke-linejoin="round"/>`);
  k.gloss('M52 108 Q62 50 118 36 Q80 64 72 118 Z', 0.9);
  return k.done();
};

// ------------------------------------------------------------- SMALL GLYPHS
A.icon_plus = () => { const k = icon(); k.add(tube('M128 44 L128 212 M44 128 L212 128', '#FFFFFF', 44, 14)); return k.done(); };
A.icon_close = () => { const k = icon(); k.add(tube('M62 62 L194 194 M194 62 L62 194', '#FFFFFF', 44, 14)); return k.done(); };
A.icon_check = () => {
  const k = icon();
  k.add(`<circle cx="128" cy="128" r="106" fill="${k.tone('#8CFF7A', '#12A02E')}" stroke="${INK}" stroke-width="11"/>`);
  k.gloss('M40 110 Q50 40 128 30 Q70 60 62 120 Z', 0.8);
  k.add(tube('M76 132 L112 168 L184 92', '#FFFFFF', 28, 10));
  return k.done();
};
A.icon_arrow = () => { const k = icon(); k.add(path('M40 100 L150 100 L150 50 L230 128 L150 206 L150 156 L40 156 Z', k.tone('#FFFFFF', '#D8E6FF'), 12)); return k.done(); };
A.icon_star = () => {
  const k = icon();
  k.add(path('M128 18 L160 88 L236 94 L178 144 L196 220 L128 180 L60 220 L78 144 L20 94 L96 88 Z', k.tone('#FFF6A8', '#FFA000', '#FFD23F'), 12));
  k.gloss('M128 40 L100 100 L44 104 L92 118 Z', 0.8);
  return k.done();
};
A.icon_lock = () => {
  const k = icon();
  k.add(tube('M80 118 L80 88 Q80 36 128 36 Q176 36 176 88 L176 118', '#C9CFE8', 22, 10));
  k.add(path('M50 116 L206 116 Q222 116 222 132 L222 220 Q222 236 206 236 L50 236 Q34 236 34 220 L34 132 Q34 116 50 116 Z', k.tone('#FFE680', '#E08A00', '#FFC21F'), 11));
  k.gloss('M46 128 L210 128 L210 150 L46 150 Z', 0.55);
  k.add(`<circle cx="128" cy="166" r="18" fill="${INK}"/><path d="M120 170 L136 170 L140 208 L116 208 Z" fill="${INK}"/>`);
  return k.done();
};
A.icon_timer = () => {
  const k = icon();
  k.add(path('M108 18 L148 18 L148 44 L108 44 Z', '#FF5A6E', 9));
  k.add(path('M186 50 L208 72 L196 84 L174 62 Z', '#FF5A6E', 8));
  k.add(`<circle cx="128" cy="144" r="96" fill="${k.tone('#8FE3FF', '#1E7BFF')}" stroke="${INK}" stroke-width="11"/>`);
  k.add(`<circle cx="128" cy="144" r="74" fill="#FFFFFF" stroke="${INK}" stroke-width="7"/>`);
  k.add(`<path d="M128 144 L128 70 A74 74 0 0 1 192 106 Z" fill="#FFD23F" opacity="0.85"/>`);
  k.add(tube('M128 144 L128 92', INK, 10, 0), tube('M128 144 L164 160', INK, 10, 0));
  k.add(`<circle cx="128" cy="144" r="10" fill="#FF5A6E" stroke="${INK}" stroke-width="5"/>`);
  return k.done();
};
A.icon_hourglass = () => {
  const k = icon();
  k.add(path('M56 20 L200 20 Q212 20 212 32 L212 40 L44 40 L44 32 Q44 20 56 20 Z', '#B06A2E', 9));
  k.add(path('M56 216 L200 216 Q212 216 212 228 L212 236 L44 236 L44 228 Q44 216 56 216 Z', '#B06A2E', 9));
  k.add(path('M64 40 L192 40 Q192 104 138 128 Q192 152 192 216 L64 216 Q64 152 118 128 Q64 104 64 40 Z', '#E6F7FF', 10));
  k.add(plain('M84 64 L172 64 Q164 102 128 120 Q92 102 84 64 Z', '#FFC93A'));
  k.add(plain('M128 150 L132 200 L178 206 Q176 172 128 150 Z', '#FFC93A'), plain('M128 150 L124 200 L78 206 Q80 172 128 150 Z', '#FFC93A'));
  k.gloss('M74 48 L92 48 Q94 94 120 120 Q84 108 74 48 Z', 0.8);
  return k.done();
};
A.icon_shield = () => {
  const k = icon();
  k.add(path('M128 18 L220 50 Q224 150 128 238 Q32 150 36 50 Z', k.tone('#9BFF8A', '#12A02E', '#4BD84A'), 12));
  k.add(path('M128 40 L200 64 Q200 144 128 214 Q56 144 56 64 Z', 'none', 0), `<path d="M128 40 L200 64 Q200 144 128 214 Q56 144 56 64 Z" fill="none" stroke="#FFFFFF" stroke-width="6" opacity="0.55"/>`);
  k.gloss('M52 60 L126 34 L126 60 Q80 70 64 140 Q48 110 52 60 Z', 0.75);
  k.add(tube('M86 128 L118 160 L174 98', '#FFFFFF', 24, 10));
  return k.done();
};
A.icon_warning = () => {
  const k = icon();
  k.add(path('M128 20 Q140 20 146 30 L238 200 Q246 222 222 224 L34 224 Q10 222 18 200 L110 30 Q116 20 128 20 Z', k.tone('#FFE95A', '#FF8A00', '#FFC21F'), 12));
  k.gloss('M120 44 L44 190 L64 190 L128 60 Z', 0.6);
  k.add(tube('M128 82 L128 150', INK, 22, 0), `<circle cx="128" cy="186" r="14" fill="${INK}"/>`);
  return k.done();
};
A.icon_drop = () => {
  const k = icon();
  k.add(`<ellipse cx="128" cy="210" rx="92" ry="28" fill="#000" opacity="0.25"/>`);
  k.add(`<ellipse cx="128" cy="206" rx="80" ry="22" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-dasharray="18 12"/>`);
  k.add(path('M96 24 L160 24 L160 104 L204 104 L128 186 L52 104 L96 104 Z', k.tone('#FFFFFF', '#FFC4CC'), 12));
  k.gloss('M104 34 L116 34 L116 110 L104 110 Z', 0.9);
  return k.done();
};
A.icon_bolt = () => {
  const k = icon();
  k.add(path('M150 14 L52 142 L118 142 L92 242 L206 100 L138 100 L172 14 Z', k.tone('#FFF9B0', '#FF9D00', '#FFD600'), 12));
  k.gloss('M146 30 L80 128 L104 128 L150 40 Z', 0.9);
  k.add(spark(214, 186, 1.2), spark(46, 52, 1));
  return k.done();
};
A.icon_potion = () => {
  const k = icon();
  k.add(path('M100 20 L156 20 L156 34 L150 34 L150 88 Q214 112 214 172 Q214 238 128 238 Q42 238 42 172 Q42 112 106 88 L106 34 L100 34 Z', '#E8FBFF', 11));
  k.add(plain('M52 158 Q88 142 128 160 Q170 178 204 156 Q210 232 128 230 Q48 232 52 158 Z', '#FF4FA3'));
  k.add(plain('M52 158 Q88 142 128 160 Q170 178 204 156 L204 170 Q170 190 128 172 Q90 156 52 172 Z', '#FF9DD0', 'opacity="0.8"'));
  k.add(`<circle cx="104" cy="196" r="9" fill="#FFFFFF" opacity="0.8"/><circle cx="148" cy="206" r="6" fill="#FFFFFF" opacity="0.8"/><circle cx="130" cy="186" r="5" fill="#FFFFFF" opacity="0.8"/>`);
  k.add(path('M94 8 L162 8 Q170 8 170 16 L170 26 Q170 34 162 34 L94 34 Q86 34 86 26 L86 16 Q86 8 94 8 Z', '#B06A2E', 8));
  k.gloss('M60 150 Q66 112 104 98 Q80 130 78 170 Z', 0.9);
  k.add(spark(216, 60, 1.2));
  return k.done();
};
A.icon_clover = () => {
  const k = icon();
  const leaf = (r) => `<g transform="rotate(${r} 128 128)">` + path('M128 124 Q84 120 76 80 Q72 44 104 44 Q122 44 128 64 Q134 44 152 44 Q184 44 180 80 Q172 120 128 124 Z', k.tone('#A6FF8A', '#1DA53C'), 10) + `</g>`;
  k.add(tube('M132 134 Q150 190 188 230', '#1DA53C', 14, 9));
  k.add(leaf(0), leaf(90), leaf(180), leaf(270));
  k.add(`<circle cx="128" cy="128" r="14" fill="#FFD23F" stroke="${INK}" stroke-width="7"/>`);
  k.add(spark(214, 40, 1.2));
  return k.done();
};
A.icon_crown = () => {
  const k = icon();
  k.add(path('M30 88 L78 132 L128 50 L178 132 L226 88 L208 206 L48 206 Z', k.tone('#FFF6A8', '#E68A00', '#FFC21F'), 12));
  k.add(path('M44 190 L212 190 L208 222 L48 222 Z', '#D97800', 10));
  k.add(`<circle cx="30" cy="84" r="16" fill="#FF4F7E" stroke="${INK}" stroke-width="8"/><circle cx="226" cy="84" r="16" fill="#FF4F7E" stroke="${INK}" stroke-width="8"/><circle cx="128" cy="44" r="18" fill="#4FD2FF" stroke="${INK}" stroke-width="8"/>`);
  k.add(path('M128 132 L148 156 L128 180 L108 156 Z', '#9A5CFF', 7));
  k.gloss('M52 110 L74 132 L66 180 L58 180 Z', 0.8);
  return k.done();
};
A.icon_gift = () => {
  const k = icon();
  k.add(path('M42 110 L214 110 L206 234 L50 234 Z', k.tone('#FF8FB0', '#D81B5A'), 11));
  k.add(path('M30 80 L226 80 Q232 80 232 86 L232 116 L24 116 L24 86 Q24 80 30 80 Z', k.tone('#FFB3C9', '#FF4F7E'), 11));
  k.add(path('M110 80 L146 80 L146 234 L110 234 Z', k.tone('#FFF09A', '#FFB400'), 8));
  k.add(tube('M128 78 Q96 22 70 42 Q56 62 128 78 Q200 62 186 42 Q160 22 128 78', '#FFD23F', 12, 8));
  k.gloss('M52 122 L72 122 L66 224 L56 224 Z', 0.8);
  k.add(spark(222, 176, 1.1), spark(34, 40, 1));
  return k.done();
};
A.icon_moneybag = () => {
  const k = icon();
  k.add(path('M100 60 Q60 110 44 168 Q34 236 128 236 Q222 236 212 168 Q196 110 156 60 Z', k.tone('#9CFF8E', '#1E8F3E', '#46C95F'), 11));
  k.add(path('M92 40 Q128 58 164 40 L156 66 Q128 76 100 66 Z', '#177A33', 9));
  k.add(tube('M150 128 Q128 114 110 126 Q98 142 126 150 Q156 158 146 176 Q130 192 104 178', '#FFFFFF', 12, 8), tube('M128 106 L128 202', '#FFFFFF', 10, 8));
  k.gloss('M66 150 Q76 104 104 80 Q92 120 88 176 Z', 0.8);
  return k.done();
};
A.icon_slots = () => {
  const k = icon();
  const cell = (x, y, fill) => path(`M${x + 12} ${y} L${x + 88} ${y} Q${x + 100} ${y} ${x + 100} ${y + 12} L${x + 100} ${y + 88} Q${x + 100} ${y + 100} ${x + 88} ${y + 100} L${x + 12} ${y + 100} Q${x} ${y + 100} ${x} ${y + 88} L${x} ${y + 12} Q${x} ${y} ${x + 12} ${y} Z`, fill, 10);
  const vio = k.tone('#C9A2FF', '#6A2FE0');
  k.add(cell(22, 22, vio), cell(134, 22, vio), cell(22, 134, vio));
  k.add(`<path d="M146 134 L222 134 Q234 134 234 146 L234 222 Q234 234 222 234 L146 234 Q134 234 134 222 L134 146 Q134 134 146 134 Z" fill="#FFFFFF" fill-opacity="0.25" stroke="#FFFFFF" stroke-width="8" stroke-dasharray="16 10"/>`);
  k.add(tube('M184 160 L184 208 M160 184 L208 184', '#8CFF7A', 14, 8));
  const face = (x, y) => `<circle cx="${x + 50}" cy="${y + 54}" r="24" fill="#FFE3CF" stroke="${INK}" stroke-width="6"/><path d="M${x + 24} ${y + 50} Q${x + 30} ${y + 20} ${x + 50} ${y + 22} Q${x + 72} ${y + 20} ${x + 76} ${y + 50} Q${x + 60} ${y + 36} ${x + 24} ${y + 50} Z" fill="#271A6B"/>`;
  k.add(face(22, 22), face(134, 22), face(22, 134));
  return k.done();
};
A.icon_treadmill = () => {
  const k = icon();
  // handle post
  k.add(tube('M190 176 L204 70', '#8A96B8', 16, 9), tube('M170 74 L228 66', '#FF5A6E', 16, 9));
  // console
  k.add(path('M178 54 L230 48 L234 78 L182 84 Z', '#2B2356', 8));
  k.add(`<path d="M190 62 L222 58" stroke="#4FFFB0" stroke-width="6" stroke-linecap="round"/>`);
  // belt base
  k.add(path('M22 176 L226 176 Q240 176 240 190 L240 204 Q240 218 226 218 L22 218 Q10 218 10 204 L10 190 Q10 176 22 176 Z', '#2B2356', 10));
  k.add(path('M28 160 L220 160 Q232 160 232 172 L232 180 L16 180 L16 172 Q16 160 28 160 Z', k.tone('#6FD8FF', '#1B63D6'), 9));
  k.add(`<circle cx="40" cy="198" r="12" fill="#C9CFE8" stroke="${INK}" stroke-width="6"/><circle cx="210" cy="198" r="12" fill="#C9CFE8" stroke="${INK}" stroke-width="6"/>`);
  k.add(`<path d="M66 198 L180 198" stroke="#5A4FA0" stroke-width="6" stroke-dasharray="14 10" stroke-linecap="round"/>`);
  // speed streaks above belt
  k.add(tube('M40 128 L120 128', '#7FE6FF', 12, 8), tube('M70 98 L140 98', '#35B8FF', 12, 8), tube('M30 70 L90 70', '#7FE6FF', 10, 7));
  k.add(spark(160, 40, 1.1, '#FFF6A8'));
  return k.done();
};
A.icon_farm = () => {
  const k = icon();
  k.add(path('M16 236 L240 236 L240 222 Q128 200 16 222 Z', '#4BD84A', 8));
  k.add(path('M40 116 L128 40 L216 116 L216 228 L40 228 Z', k.tone('#FF7A6B', '#C9163A', '#E83A3A'), 11));
  k.add(path('M22 124 L128 28 L234 124 L222 136 L128 54 L34 136 Z', '#FFFFFF', 9));
  k.add(path('M92 146 L164 146 L164 228 L92 228 Z', '#FFF1E0', 8));
  k.add(`<path d="M92 146 L164 228 M164 146 L92 228" stroke="#C9163A" stroke-width="9"/>`);
  k.add(path('M108 90 L148 90 L148 118 L108 118 Z', '#FFD23F', 7));
  k.add(`<path d="M128 90 L128 118 M108 104 L148 104" stroke="${INK}" stroke-width="4"/>`);
  k.gloss('M52 122 L128 56 L128 72 L60 130 L60 220 L52 220 Z', 0.5);
  k.add(path('M180 190 Q182 170 204 168 Q230 170 232 192 Q232 216 206 216 Q182 216 180 190 Z', '#FFE27A', 8));
  return k.done();
};
A.icon_sparkle = () => { const k = icon(); k.add(spark(128, 128, 7, '#FFF6A8'), spark(206, 56, 2.2), spark(56, 206, 1.8)); return k.done(); };
A.icon_equip_best = () => {
  const k = icon();
  k.add(path('M128 18 L160 88 L236 94 L178 144 L196 220 L128 180 L60 220 L78 144 L20 94 L96 88 Z', k.tone('#FFF6A8', '#FFA000', '#FFD23F'), 12));
  k.add(tube('M128 172 L128 104 M100 130 L128 102 L156 130', '#FFFFFF', 18, 9));
  return k.done();
};
A.icon_skip = () => { // fast-forward chevrons (hatch skip)
  const k = icon();
  k.add(path('M28 50 L128 128 L28 206 Z', k.tone('#FFFFFF', '#CFE2FF'), 12), path('M128 50 L228 128 L128 206 Z', k.tone('#FFFFFF', '#CFE2FF'), 12));
  return k.done();
};
A.icon_info = () => {
  const k = icon();
  k.add(`<circle cx="128" cy="128" r="106" fill="${k.tone('#8FE3FF', '#1E7BFF')}" stroke="${INK}" stroke-width="11"/>`);
  k.add(tube('M128 116 L128 190', '#FFFFFF', 30, 0), `<circle cx="128" cy="76" r="18" fill="#FFFFFF"/>`);
  return k.done();
};

module.exports = A;
