// PREVIEW-ONLY developer panel. Deliberately styled as a hazard-taped dev tool so
// it can never be mistaken for production UI. Delete `PREVIEW_Panel` (and the
// PREVIEW_* scripts) when integrating into a real game.
const { U2, px } = require('../lib/rbx');
const { INK } = require('../lib/theme');
const { box, label, img, stroke, list, padding, scaleMod, gridLayout } = require('../lib/components');

const SECTIONS = [
  ['MENUS', [['Shop', 'menu:Shop'], ['Index', 'menu:Index'], ['Eggs', 'menu:Eggs'], ['Chars', 'menu:Characters'], ['Upgrade', 'menu:Upgrade'], ['Close', 'menu:none']]],
  ['INDEX', [['Unlock +1', 'index:unlockNext'], ['Lock all', 'index:lockAll'], ['All', 'index:unlockAll']]],
  ['EGG CARDS', [['Cycle', 'eggs:cycle'], ['All Ready', 'eggs:allReady'], ['Reset', 'eggs:reset']]],
  ['HATCH TIMER', [['Start 60s', 'hatch:start'], ['Hatching', 'hatch:hatching'], ['READY', 'hatch:ready']]],
  ['EGG CARRY', [['Unsafe', 'carry:unsafe'], ['Secured', 'carry:secured'], ['Hide', 'carry:hidden']]],
  ['CHARACTERS', [['Equip Best', 'chars:equipBest'], ['Unequip', 'chars:unequipAll'], ['+ Dupe', 'chars:addDupe']]],
  ['UPGRADE', [['Char', 'upgrade:tab:Character'], ['Treadmill', 'upgrade:tab:Treadmill'], ['Farm', 'upgrade:tab:Farm'], ['Toggle MAX', 'upgrade:toggleMax']]],
];

function chipBtn(text, action, lo) {
  const { I } = require('../lib/rbx');
  const { gprops, corner } = require('../lib/components');
  return I('TextButton', {
    ...gprops({ name: `Chip_${action.replace(/[^A-Za-z0-9]/g, '_')}`, size: px(66, 24), lo, bg: '#2F2566' }),
    Text: '', AutoButtonColor: true, $attrs: { PreviewAction: action },
  }, corner(7), stroke(1.5, '#6F5FD0'),
  label('Label', text, { ts: 13, font: 'Fredoka', stroke: 0, color: '#EDE8FF' }));
}

function panel() {
  let lo = 0;
  const body = [];
  for (const [title, chips] of SECTIONS) {
    body.push(label(`H_${title.replace(/\s/g, '')}`, title, { size: U2(1, 0, 0, 14), ts: 12, font: 'Fredoka', xa: 'Left', stroke: 0, color: '#FFD23F', lo: lo++ }));
    const rows = Math.ceil(chips.length / 3);
    body.push(box(`G_${title.replace(/\s/g, '')}`, { size: U2(1, 0, 0, rows * 24 + (rows - 1) * 4), lo: lo++ },
      gridLayout(66, 24, 4, 4, 'Left'),
      ...chips.map(([t, a], i) => chipBtn(t, a, i))));
  }
  return box('PREVIEW_Panel', { anchor: [1, 0], pos: U2(1, -12, 0, 64), size: px(234, 428), attrs: { Layer: 'Preview', PREVIEW_ONLY: true } },
    scaleMod(),
    box('Frame', { size: U2(1, 0, 1, 0), bg: '#140C2B', bgT: 0.08, r: 12 }, stroke(2.5, '#FFD23F'),
      box('Header', { size: U2(1, 0, 0, 40), bg: '#FFD23F', r: 12 },
        img('Tape', 'pattern_hazard', { tile: 22, r: 12, imgT: 0.25 }),
        box('Plate', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: U2(1, -14, 0, 30), bg: INK, r: 8 },
          label('Title', 'PREVIEW MODE', { pos: U2(0, 8, 0, 1), size: U2(1, -40, 0, 17), ts: 15, xa: 'Left', stroke: 0, color: '#FFD23F' }),
          label('Sub', 'SAMPLE DATA - NOT GAMEPLAY', { pos: U2(0, 8, 0, 16), size: U2(1, -40, 0, 12), ts: 10, xa: 'Left', font: 'Fredoka', stroke: 0, color: '#FFFFFF' }),
          (() => {
            const { I } = require('../lib/rbx');
            const { gprops, corner } = require('../lib/components');
            return I('TextButton', { ...gprops({ name: 'Collapse', size: px(24, 22), pos: U2(1, -4, 0.5, 0), anchor: [1, 0.5], bg: '#FFD23F' }), Text: '', $attrs: { PreviewAction: 'panel:toggle' } },
              corner(6), label('Label', '-', { ts: 18, stroke: 0, color: INK }));
          })())),
      box('Body', { pos: U2(0, 0, 0, 44), size: U2(1, 0, 1, -48) }, padding(2, 8, 6, 9), list('Vertical', 3, 'Left', 'Top'), ...body)));
}

module.exports = { panel };
