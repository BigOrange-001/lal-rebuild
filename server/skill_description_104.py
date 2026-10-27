"""Render manual coefficients directly without changing execution parameters."""
import re
from skill_balance_overlay import _MANUAL_DAMAGE_PERCENT_INDICES

HEAL_SHIELD = {
 'illaoi_n':(1,2),'illaoi_c':(2,3),'jayce_n':(3,4),
 'nidalee_c':(0,1),'kayle_n':(2,3),'maokai_n':(1,2),'maokai_c':(1,),
 'gangplank_n':(2,3),'riven_n':(3,4),'orianna_n':(0,1),'orianna_c':(1,2),
 'nunu_n':(2,3),'nunu_c':(0,1),'alistar_c':(0,1),'diana_c':(2,3),
 'tahm_n':(1,2),'tahm_c':(0,1),
 'nurse_n':(0,1,2),'nurse_c':(0,),
}
SKIN_DAMAGE = {'cat_n':(0,1),'cat_c':(0,), 'polar_n':(0,), 'polar_c':(0,),
               'santa_n':(0,), 'santa_c':(0,)}
TOKEN = re.compile(r'\{scale:([0-9.]+):([0-9.]+)\}|([0-9]+(?:\.[0-9]+)?)%')


def scale_manual_output_text(row, kind, factor, *, all_effects=False, damage_only=False):
    positions = set(_MANUAL_DAMAGE_PERCENT_INDICES.get(kind, SKIN_DAMAGE.get(kind, ()))) | set(HEAL_SHIELD.get(kind, ()))
    if damage_only:
        positions -= set(HEAL_SHIELD.get(kind, ()))
    if all_effects:
        from captain_strength import _MANUAL_EFFECT_PERCENT_INDICES
        positions |= set(_MANUAL_EFFECT_PERCENT_INDICES.get(kind, ()))
    # This is a description of the cancelled old explosion, not an emitted hit.
    if kind == 'kaelthas_c': positions.discard(2)
    for field in ('info','rankInfoTemplate'):
        if not isinstance(row.get(field),str): continue
        index = 0
        def replace(m):
            nonlocal index
            selected = index in positions
            index += 1
            if not selected:return m[0]
            if m[3] is not None:return f'{float(m[3])*factor:.8f}'.rstrip('0').rstrip('.')+'%'
            return '{scale:'+str(round(float(m[1])*factor,10))+':'+str(round(float(m[2])*factor,10))+'}'
        row[field] = TOKEN.sub(replace,row[field])

    if all_effects:
        from captain_strength import _MANUAL_FLAT_STAT_LABELS
        label = _MANUAL_FLAT_STAT_LABELS.get(kind)
        if label:
            for field in ('info','rankInfoTemplate'):
                if isinstance(row.get(field),str):
                    row[field]=re.sub(r'(\d+(?:\.\d+)?)点'+label,lambda m:f'{float(m[1])*factor:g}点'+label,row[field])
