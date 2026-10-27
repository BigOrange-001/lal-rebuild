"""Custom raster VFX choreography shared by AIR and the review scenes."""
import json,sys,re,base64,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def part(id,at='target',delay=0,scale=.75,life=.65,**kw):
 return dict(id=id,at=at,delay=delay,scale=scale,life=life,**kw)
def shot(bullet,impact,scale=.75):
 return [part(bullet,'flight',scale=.55,life=.24),part(impact,delay=.24,scale=scale)]
PROFILES={
 '1201':dict(name='盖伦 · 圣剑斩击',parts=[part('e006',scale=.9),part('e007',delay=.12,scale=.65)]),
 '1203':dict(name='瑞兹 · 契约冲击',parts=shot('e202','e012')+[part('e069',delay=.32,scale=.55)]),
 '1204':dict(name='布里茨 · 电弧冲击',parts=shot('e025','e020')),
 '1206':dict(name='薇恩 · 银弩',parts=shot('e030','e015',.65)),
 '1207':dict(name='阿狸 · 魅惑狐火',parts=shot('e521','e543',.8)),
 '1209':dict(name='提莫 · 毒弹',parts=shot('e032','e027',.7)),
 '1210':dict(name='锐雯 · 连段刀光',parts=[part('e006',scale=.9,rotation=-.45),part('e014',delay=.12,scale=.8,rotation=.55)]),
 '1211':dict(name='凯特琳 · 狙击弹道',parts=shot('e508','e023',.8)),
 '1213':dict(name='伊泽瑞尔 · 奥术射门',parts=shot('e202','e542',.85)),
 '1214':dict(name='崔斯特 · 裁决爆发',parts=shot('e204','e011',1.0)+[part('e069',delay=.3,scale=.45)]),
 '1215':dict(name='李青 · 音波追击',parts=shot('e506','e009',.85)),
 '1216':dict(name='艾尼维亚 · 冰晶碎裂',parts=shot('e303','e201',.9)),
 '1218':dict(name='费德提克 · 幽影侵袭',parts=[part('e718','flight',scale=.5,life=.28),part('e069',delay=.2,scale=.8)]),
 '1219':dict(name='亚索 · 疾风斩',parts=[part('e503','flight',scale=.7,life=.2),part('e006',delay=.15,scale=.85),part('e502',delay=.28,scale=.7)]),
 '1221':dict(name='安妮 · 烈焰',parts=shot('e010','e541',.75)),
 '1228':dict(name='娑娜 · 和弦震荡',parts=[part('e001','source',scale=.8),part('e009','flight',scale=.65,life=.28),part('e015',delay=.28,scale=.6)]),
 '1227':dict(name='白娘子 · 灵蛇法术',parts=shot('e545','e026',.85)),
 '1140':dict(name='艾克 · 时空打击',parts=shot('e033','e522',.9)),
 'rings':dict(name='银弩 · 三环引爆',parts=[part('e709',scale=.8),part('e015',delay=.12,scale=1.15),part('e006',delay=.2,scale=.65)]),
 'time_rings':dict(name='时间共振 · 引爆',parts=[part('e522',scale=1.05,rotation=-.8),part('e003',delay=.12,scale=1.1)]),
 'egg_ready':dict(name='彩蛋 · 毒雾爆破',parts=[part('e026',scale=.8),part('e027',delay=.08,scale=1.0),part('e543',delay=.18,scale=.7)]),
 'time':dict(name='回溯 · 时空残光',parts=[part('e003',scale=1.15,life=.8,spin=-3),part('e522',delay=.12,scale=.8,spin=-4),part('e033',delay=.2,scale=.6)]),
 'guard':dict(name='守护 · 金色屏障',parts=[part('e709',scale=1.0,life=.7),part('e011',delay=.1,scale=.75)]),
 'rebirth':dict(name='冰晶 · 重生爆发',parts=[part('e708',scale=1.15,life=.85),part('e201',delay=.15,scale=1.0),part('e015',delay=.3,scale=1.1)]),
 'crows':dict(name='群鸦 · 暗影风暴',parts=[part('e718',scale=1.2,life=.9,spin=3),part('e069',delay=.1,scale=.85),part('e718',delay=.22,scale=.9,spin=-3)]),
 'cold':dict(name='冰霜 · 冻结冲击',parts=[part('e201',scale=.8),part('e015',delay=.12,scale=.7)]),
 'cleanse':dict(name='净化 · 驱散光辉',parts=[part('e026',scale=.8),part('e011',delay=.12,scale=.8)]),
 'growth':dict(name='成长 · 能量汇聚',parts=[part('e012',scale=.65,life=.7,rise=-30),part('e003',delay=.15,scale=.75)]),
 'bear':dict(name='提伯斯 · 烈焰涌动',parts=[part('e541',scale=.8,life=.8),part('e017',delay=.18,scale=.65)]),
 'bomb':dict(name='延迟炸弹 · 爆破',parts=[part('e017',scale=1),part('e023',delay=.14,scale=.9)]),
 'ball':dict(name='传球 · 奥术光球',parts=shot('e506','e003',.55)),
 'shot':dict(name='射门 · 能量迸发',parts=[part('e008',scale=.65),part('e542',delay=.12,scale=.75)]),
 'wanted':dict(name='狙击 · 锁定闪光',parts=[part('e706',scale=.75,life=.6)]),
 'exposed':dict(name='破绽 · 电火花',parts=[part('e020',scale=.7),part('e007',delay=.1,scale=.6)]),
 'charmed':dict(name='魅惑 · 心焰',parts=[part('e521',scale=.8,life=.7),part('e543',delay=.15,scale=.55)]),
 'contract':dict(name='契约 · 暗紫烙印',parts=[part('e012',scale=.7),part('e069',delay=.12,scale=.45)]),
 'airborne':dict(name='疾风 · 击飞',parts=[part('e503',scale=.9,rise=-45),part('e008',delay=.1,scale=.8,rise=-30)]),
 'windmark':dict(name='风刃 · 穿透',parts=[part('e502',scale=.8),part('e006',delay=.1,scale=.65)]),
 'sonic':dict(name='音波 · 回响',parts=[part('e001',scale=.7),part('e003',delay=.15,scale=1.05)]),
 'sap':dict(name='汲取 · 生命回流',parts=[part('e026',scale=.75),part('e027',delay=.1,scale=.45)]),
}
PROFILES.update({
 '1201_ult':dict(name='盖伦 · 圣剑裁决',parts=[part('e024',scale=1.1),part('e007',delay=.12,scale=.8)]),
 '1203_ult':dict(name='瑞兹 · 契约爆发',parts=[part('e012',scale=1.05),part('e069',delay=.18,scale=.8)]),
 '1204_ult':dict(name='布里茨 · 静电释放',parts=[part('e020',scale=1),part('e009',delay=.14,scale=.85)]),
 '1207_ult':dict(name='阿狸 · 魅惑焦点',parts=shot('e521','e543',1.15)),
 '1210_ult':dict(name='锐雯 · 觉醒剑波',parts=[part('e503','flight',scale=1.1,life=.22),part('e006',delay=.22,scale=1.2)]),
 '1211_ult':dict(name='凯特琳 · 致命狙击',parts=shot('e508','e023',1.1)),
 '1216_ult':dict(name='艾尼维亚 · 暴风雪',parts=[part('e201',scale=1.15,life=.9),part('e003',delay=.18,scale=1)]),
 '1218_ult':dict(name='费德提克 · 群鸦风暴',parts=[part('e718',scale=1.3,life=.9,spin=2),part('e069',delay=.2,scale=1.0)]),
 '1221_ult':dict(name='安妮 · 提伯斯烈焰',parts=[part('e541',scale=1.1,life=.85),part('e017',delay=.18,scale=.9)]),
 '1140_ult':dict(name='艾克 · 时空断裂',parts=[part('e003',scale=1.3,life=.8,spin=-3),part('e522',delay=.15,scale=1.15,spin=-4)]),
})

# Old choreography IDs are converted at authoring time; exported runtime contains only new sprites.
REPLACE={'e001':12,'e003':12,'e006':0,'e007':8,'e008':30,'e009':15,'e010':5,'e011':31,'e012':10,'e014':1,'e015':9,'e017':8,'e020':15,'e023':8,'e024':3,'e025':15,'e026':14,'e027':11,'e030':7,'e032':11,'e033':26,'e069':10,'e201':9,'e202':4,'e204':7,'e303':4,'e502':1,'e503':1,'e506':4,'e508':7,'e521':24,'e522':26,'e541':29,'e542':8,'e543':22,'e545':6,'e706':7,'e708':12,'e709':13,'e718':20}
for profile in PROFILES.values():
 for piece in profile['parts']:piece['id']='c'+str(REPLACE[piece['id']])
PROFILES['ball']['parts'][0]['id']='c19'
PROFILES['rebirth']['parts'][0]['id']='c21'
PROFILES['1210']['parts'][0]['id']='c2'
PROFILES['egg_ready']['parts'].insert(0,part('c17',scale=.65,life=.4,rise=-12))

STATE_NAMES={'wanted':'狙击锁定','exposed':'破绽','charmed':'魅惑','cold':'寒冷','airborne':'浮空','contract':'契约','windmark':'疾风印记','rings':'银弩三环','time_rings':'时间共振','sonic':'音波锁定','ball':'持球','guard':'守护','shot':'射门机会','phase':'相位强化','awake':'锐雯觉醒','rebirth':'冰晶重生','crows':'群鸦引导','growth':'永久成长','bear':'提伯斯成长','command':'协同待命','dance':'剑舞阶段','trap':'夹子','egg':'彩蛋','egg_ready':'成熟彩蛋','time':'回溯残影','aura_heal':'治疗和弦','aura_guard':'守护和弦','hunt':'狩猎','moon':'月光','bomb':'延迟炸弹','infection':'侵染','counter':'反击准备','sap':'汲取','root':'禁锢','grey':'灰色生命','charge':'电荷','hammer':'锤形态','summon':'召唤归属','zone':'持续区域','channel':'蓄力'}
STATE_IDS={'wanted':[7,7],'exposed':[23],'charmed':[24],'cold':[9],'airborne':[1],'contract':[10],'windmark':[1],'rings':[12,12],'time_rings':[26,26],'sonic':[30],'ball':[19],'guard':[28,13],'shot':[19,15],'phase':[26,1],'awake':[22,2],'rebirth':[21],'crows':[20,20,20],'growth':[14],'bear':[29],'command':[29,28],'dance':[2,2,2],'trap':[18],'egg':[16],'egg_ready':[17],'time':[26],'aura_heal':[14],'aura_guard':[13],'hunt':[23],'moon':[1],'bomb':[5],'infection':[10],'counter':[0,13],'sap':[14],'root':[27],'grey':[25],'charge':[15],'hammer':[0],'summon':[12],'zone':[8,5],'channel':[30,12]}

def build():
 from PIL import Image
 data={'sheets':[],'states':{k:{'name':n,'ids':['c'+str(i) for i in STATE_IDS[k]]} for k,n in STATE_NAMES.items()}}
 for name in ('energy','states'):
  p=ROOT/'client/resources/app/assets/effects/custom104'/f'{name}.png';im=Image.open(p)
  assert im.mode=='RGBA' and im.width==im.height and im.getchannel('A').getextrema()==(0,255)
  data['sheets'].append('data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode())
 for p in PROFILES.values():
  for x in p['parts']:assert x['id'].startswith('c') and 0<=int(x['id'][1:])<32,x['id']
 code='      private static function fxProfile104(kind:String) : Array\n      {\n         switch(kind)\n         {\n'
 for key,p in PROFILES.items():code+='            case '+json.dumps(key)+': return '+json.dumps(p['parts'],separators=(',',':'))+';\n'
 code+='         }\n         return [];\n      }\n'
 (ROOT/'client/src/native_effect_profiles_104.aspart').write_text(code,encoding='utf8')
 out=ROOT.parent.parent/'outputs/battle-effects-20261027';out.mkdir(parents=True,exist_ok=True)
 (out/'native-profiles.json').write_text(json.dumps(PROFILES,ensure_ascii=False,indent=2),encoding='utf8')
 template=(ROOT/'scripts/native_effect_preview_104.html').read_text('utf8')
 template=template.replace('/*PAYLOAD*/',json.dumps(data,separators=(',',':')).replace('</','<\\/')).replace('/*PROFILES*/',json.dumps(PROFILES,ensure_ascii=False))
 (out/'index.html').write_text(template,encoding='utf8')
 manifest=ROOT/'client/resources/assets-manifest.json';entries=json.loads(manifest.read_text('utf8'))
 for name in ('energy','states'):
  rel=f'resources/app/assets/effects/custom104/{name}.png';p=ROOT/'client'/rel
  entries=[e for e in entries if e['path']!=rel]
  entries.append({'apk_entry':f'assets/assets/effects/custom104/{name}.png','path':rel,'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 manifest.write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 cfgpath=ROOT/'client/build.json';cfg=json.loads(cfgpath.read_text('utf8'));cfg['assets_manifest']['sha256']=hashlib.sha256(manifest.read_bytes()).hexdigest();cfgpath.write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 (out/'custom-coverage.json').write_text(json.dumps({'components':32,'profiles':len(PROFILES),'states':data['states'],'original_effect_assets':False},ensure_ascii=False,indent=2),encoding='utf8')
 print(f'32 custom sprites, {len(PROFILES)} skill choreographies, {len(STATE_NAMES)} state previews')
if __name__=='__main__':build()
