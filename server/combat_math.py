"""Scalar combat formulas from Avatar.as. No full turn/skill simulator yet."""
import math
from combat_rules import ratio_enabled

def to_int(value):
 # Tools.toInt: int(Number.toFixed(5)); finite battle magnitudes are expected.
 if not math.isfinite(value):raise ValueError('combat values must be finite')
 return int(float(f'{value:.5f}'))

def chance(first,second,base,cap,denominator,slope=100):
 if denominator<=0 or first<0 or second<0:raise ValueError('invalid probability parameters')
 return to_int(min(cap,max(0,base+slope*(first-second)/(first+second+denominator))))

def miss_chance(hit,flee,attack,rules=None):return chance(flee,hit,attack[4],attack[6],attack[9],rules.get('miss_slope',40) if ratio_enabled(rules) else 100)
def crit_chance(critical,toughness,attack,rules=None):return chance(critical,toughness,attack[5],attack[7],attack[11],rules.get('crit_slope',60) if ratio_enabled(rules) else 100)


def ratio_reduction(defense,base_attack,exponent=1.5,midpoint=0.7,cap=0.9):
 if exponent<=0 or midpoint<=0 or not 0<=cap<=1:raise ValueError('invalid defense curve')
 ratio=max(0,defense)/max(1,base_attack)
 if ratio==0:return 0.0
 # The reciprocal form avoids overflow for large defense/attack ratios.
 return min(cap,1/(1+(midpoint/ratio)**exponent))


def defense_damage(amount,defense,base_attack,minimum=0.1,rules=None):
 if ratio_enabled(rules):
  reduction=ratio_reduction(defense,base_attack,rules.get('reduction_exponent',1.5),rules.get('defense_attack_midpoint',0.7),1-minimum)
  return to_int(amount*(1-reduction))
 return to_int(max(amount*minimum,amount-to_int(defense)))
def critical_multiplier(critical,attack):
 return attack[3]+critical*attack[16]/(critical+attack[12])

def damage_before_final(raw,sign_attacker,sign_defender,damage_type,physical_defense,magic_defense,attack,extra_rate=1,*,base_attack=1,rules=None):
 # Input defense is already adjusted for talent, as in Avatar.countDamage.
 sign=attack[2] if sign_attacker%3==sign_defender-1 else 1
 amount=to_int(raw*sign)
 if damage_type==1:amount=defense_damage(amount,physical_defense,base_attack,attack[0],rules)
 elif damage_type==2:amount=defense_damage(amount,magic_defense,base_attack,attack[0],rules)
 elif damage_type==3:amount*=attack[1]
 elif damage_type in (0,5):amount=0
 return to_int(to_int(amount)*extra_rate)

def settle_damage(amount,critical_rate,toughness,shield,attack,talent_rate=0):
 # Avatar.injured: two rounding stages, toughness, talent, then shield.
 if min(amount,toughness,shield)<0:raise ValueError('negative combat input')
 value=to_int(to_int(amount*critical_rate)*attack[21])
 value=to_int(value/(1+toughness*attack[15]/(toughness+attack[13])))
 value=to_int(value+value*talent_rate)
 absorbed=min(shield,value)
 return {'health_damage':value-absorbed,'shield_left':shield-absorbed,'absorbed':absorbed}

def level_stats(avatar,level,*,enforce_cap=True):
 if not isinstance(level,int) or level<1 or (enforce_cap and level>avatar['tl'][4]):raise ValueError('level outside configured bounds')
 pl=avatar['pl']
 # Avatar's base getters use int(), before their later Tools.toInt calls.
 # Preserve that truncation for templates with fractional base/growth values.
 return {key:int(pl[i]+pl[i+1]*(level-1)) for i,key in [(0,'health'),(2,'attack'),(4,'physical_defense'),(6,'magic_defense')]}
