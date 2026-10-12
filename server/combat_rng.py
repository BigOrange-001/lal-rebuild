"""Exact integer RNG port from com/meng52/game/module/map/Random.as.

This is one component of combat reconstruction, not a complete simulator.
"""
def int32(value):
 value=int(value)&0xffffffff
 return value-0x100000000 if value&0x80000000 else value

def as3_remainder(dividend,divisor):
 # AS3/ECMAScript remainder keeps the dividend sign; Python % does not.
 return dividend%divisor if dividend>=0 else -((-dividend)%divisor)

class CombatRandom:
 def __init__(self,seed=82684):
  self.seed=self.seed2=int32(seed)
  self.calls=0
 def _next(self,seed,maximum):
  if not isinstance(maximum,int) or maximum<=0:
   raise ValueError('maximum must be a positive integer')
  shifted=int32(int32(seed+9991)<<3)
  seed=as3_remainder(shifted+6700417,239641)
  return seed,as3_remainder(seed,maximum)
 def get_random(self,maximum=100):
  self.seed,result=self._next(self.seed,maximum)
  self.calls+=1
  return result
 def get_random2(self,maximum=100):
  self.seed2,result=self._next(self.seed2,maximum)
  return result
