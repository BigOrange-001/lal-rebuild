"""Scalar combat formulas from Avatar.as. No full turn/skill simulator yet."""
import math

def to_int(value):
 # Tools.toInt: int(Number.toFixed(5)); finite battle magnitudes are expected.
 if not math.isfinite(value):raise ValueError('combat values must be finite')
 return int(float(f'{value:.5f}'))

def chance(first,second,base,cap,denominator):
 if denominator<=0 or first<0 or second<0:raise ValueError('invalid probability parameters')
 return to_int(min(cap,max(0,base+100*(first-second)/(first+second+denominator))))

def miss_chance(hit,flee,attack):return chance(flee,hit,attack[4],attack[6],attack[9])
def crit_chance(critical,toughness,attack):return chance(critical,toughness,attack[5],attack[7],attack[11])
def critical_multiplier(critical,attack):
 return attack[3]+critical*attack[16]/(critical+attack[12])

def damage_before_final(raw,sign_attacker,sign_defender,damage_type,physical_defense,magic_defense,attack,extra_rate=1):
 # Input defense is already adjusted for talent, as in Avatar.countDamage.
 sign=attack[2] if sign_attacker%3==sign_defender-1 else 1
 amount=to_int(raw*sign)
 if damage_type==1:amount=max(amount*attack[0],amount-to_int(physical_defense))
 elif damage_type==2:amount=max(amount*attack[0],amount-to_int(magic_defense))
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
 return {key:to_int(pl[i]+pl[i+1]*(level-1)) for i,key in [(0,'health'),(2,'attack'),(4,'physical_defense'),(6,'magic_defense')]}
