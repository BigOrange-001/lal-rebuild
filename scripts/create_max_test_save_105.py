"""Create an isolated max-progress save using the actual 1.0.5 configuration.

This only writes a new database. It never opens a player's live save or changes
game rules, the APK, daily limits, or existing saves.
"""
from pathlib import Path
import argparse
import collections
import gzip
import hashlib
import json
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'server'))
from gateway import Backend
from gameplay_common import grant_reward,equipment_exclusive_ids
from gameplay_roster import GameplayRosterEquipment
from cultivation_rules import active,cap,used,WEIGHTS,SCHEMA
from equipment_growth_v2 import effective_cap
from gameplay_energy import energy_state


def highest(rows,predicate):
    families = {}
    for key,row in rows.items():
        if not predicate(key,row):
            continue
        family,quality = key.rsplit('_',1)
        if family not in families or int(quality)>int(families[family].rsplit('_',1)[1]):
            families[family] = key
    return sorted(families.values())


def verify_profile(p,cfg,roster,hero_ids,gear_ids):
    simple = cfg['system_simple']
    assert len(p['avatars'])==len(hero_ids)
    assert {h['aid'].split('|')[0] for h in p['avatars'].values()}==set(hero_ids)
    for hero in p['avatars'].values():
        aid = hero['aid'].split('|')[0]
        assert hero['lv']==roster._hero_level_cap(aid,hero)
        assert hero['slv']==roster._native_skill_level_cap()
        assert hero['phase']==int(simple['phase_config'][0][aid.rsplit('_',1)[1]][1])
        if active(simple,hero):
            assert used(hero,simple)==cap(hero,simple)
            assert hero['limit_break']==1 and hero['morph']==1
    assert len(p['my_equips'])==len(gear_ids)*6
    assert collections.Counter(e['eid'] for e in p['my_equips'].values())==dict.fromkeys(gear_ids,6)
    gear_cap = effective_cap(p['lv'],int(cfg['vip']['15']['equip_lvmax']))
    for item in p['my_equips'].values():
        assert item['lv']==gear_cap
        assert int(item['eid'].rsplit('_',1)[1])+int(item['alchemy'][1])==8
        assert item['alchemy'][0]==0 and item['magic']==[100]*4 and item['magic_stage5']==1
        assert item['rune_lv']==int(simple['equipment_magic']['rune_max'])
        assert item['halo']['lv']==int(simple['equipwash'][5])
        if int(cfg['equip'][item['eid']]['type'])==6:
            assert item['slv']==roster._native_skill_level_cap()
    for bucket,table in [('normal','battle_main'),('hard','battle_main'),('ploy','battle_ploy')]:
        for chapter,row in cfg[table].items():
            assert p['combat_score'][bucket][chapter]==['1',[3]*int(row['combat'])]
    for chapter,row in cfg['battle_ploy'].items():
        expected = {f'{chapter}_{n}' for n in range(1,int(row['combat'])+1)}
        assert set(p['ploy_cids'][chapter])==expected
        assert all(p['records']['combat_ploy'][cid]>=1 for cid in expected)
    assert p['records']['tower_floor']==int(cfg['battle_ploy']['P_200']['combat'])+1
    for squad in p['team']:
        assert len(squad)==6 and len(set(squad))==6 and all(i in p['avatars'] for i in squad)
    for slots in p['as_equips']:
        assert len(slots)==6 and all(i in p['my_equips'] for i in slots)
    for hero_id in p['team'][0]:
        stats = roster.battle_attributes(p,hero_id)
        assert all(stats[k]>0 for k in ['hp','ap','de_ph','de_ma'])
    assert p['vip_lv']==15
    assert p['gold']>=100_000_000 and p['coin']>=100_000_000


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--apk',required=True,type=Path)
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True,exist_ok=True)
    database = out/'lal-1.0.5_全满测试存档.sqlite3'
    if database.exists():
        raise RuntimeError('Refusing to replace an existing save')
    # Verify the source configuration belongs to the exact shipping runtime.
    with zipfile.ZipFile(args.apk) as apk:
        runtime = json.loads(apk.read('assets/runtime/runtime-manifest.json'))
        assert runtime['version']=='1.0.5'
        config_key = 'config/reconstruction/full-config.json'
        assert hashlib.sha256((ROOT/config_key).read_bytes()).hexdigest()==runtime['files'][config_key]
    b = Backend(database,ROOT/config_key,out/'mods')
    try:
        cfg = b.config['cfg']
        simple = cfg['system_simple']
        assert 'kaisa_playtest' not in b.config and 'A_1880_3' not in cfg['avatar']
        credentials = dict(pf='local',session_key='test105',sessionid='123456')
        for method in ['register','login']:
            result = b.call(dict(method='user.'+method,params=dict(credentials,actionID='max105-'+method)))
            assert result['return_code']==0,result
        uid = result['data']['uid']
        heroes = highest(cfg['avatar'],lambda key,row:key.startswith('A_1') and len(key.split('_')[1])==4
                         and row.get('name') and '序号' not in row['name'])
        gear = highest(cfg['equip'],lambda key,row:int(row.get('type',0)) in [1,3,4,5,6])
        roster = GameplayRosterEquipment(None,b.config)
        gear_cap = effective_cap(int(simple['exp_config'][3]),int(cfg['vip']['15']['equip_lvmax']))
        talent = next(r['id'] for r in cfg['talent'].values() if r.get('rank')==7 and r.get('growth_effect')=='attack')
        hero_instances = {}
        gear_instances = collections.defaultdict(list)

        def seed(p):
            p.update(name='1.0.5全满测试',lv=int(simple['exp_config'][3]),exp=0,vip_lv=15,
                     vip_exp=int(cfg['vip']['15']['exp']),coin=100_000_000,gold=100_000_000,
                     score=10_000_000,mark=10_000_000,medal=10_000_000,avatars={},my_equips={})
            attrs = p.setdefault('attrs',{})
            attrs.update(avatar_len=2000,team_num=0,dust=[10_000_000]*4,sp=[10_000_000]*7,
                         dn_stone=10_000_000,culture_book=10_000_000,box_key=1_000_000,
                         energy_extra=100_000,fragment_energy_extra=100_000,
                         pay_total=50000,vip_gift_total_coin=200000)
            p['energy'] = {'$date':b.clock.now()-1_000_000}
            p['fragment_energy'] = {'$date':b.clock.now()-1_000_000}
            grant_reward(p,dict(heroes=[dict(aid=a,num=1) for a in heroes],
                                items=[dict(eid=e,num=6) for e in gear]),b.config,
                         allow_skin=True,allow_equipment_exclusive=True)
            for iid,h in p['avatars'].items():
                aid = h['aid'].split('|')[0]
                quality = aid.rsplit('_',1)[1]
                h.update(slv=roster._native_skill_level_cap(),exp=0,
                         phase=int(simple['phase_config'][0][quality][1]),lock=True,
                         limit_break=1 if int(quality) in [5,6] else 0,talent=talent)
                h['lv'] = roster._hero_level_cap(aid,h)
                if active(simple,h):
                    h.update(culture_schema=SCHEMA,morph=1)
                    budget = cap(h,simple)
                    for key,weight in WEIGHTS.items():
                        h[key] = (budget//4)//weight
                    h['hp'] += budget-used(h,simple)
                else:
                    # Lower-quality utility/commentator cards use their own
                    # level/cultivation ceiling instead of fabricated 125 stats.
                    budget = roster._culture_cap(h)
                    for key in WEIGHTS:
                        h[key] = budget//4
                    h['hp'] += budget-sum(h[k] for k in WEIGHTS)
                hero_instances[aid] = iid
            exclusive = set(equipment_exclusive_ids(cfg))
            for eqid,item in sorted(p['my_equips'].items(),key=lambda pair:int(pair[0][2:])):
                eid = item['eid']
                row = cfg['equip'][eid]
                item.update(lv=gear_cap,slv=roster._native_skill_level_cap() if int(row['type'])==6 else 0,
                            sexp=0,alchemy=[0,8-int(eid.rsplit('_',1)[1])],magic=[100]*4,
                            magic_stage5=1,symp=1,rune_lv=int(simple['equipment_magic']['rune_max']),
                            halo=dict(lv=int(simple['equipwash'][5]),exp=0),
                            haloLv=int(simple['equipwash'][5]),haloExp=0,lock=True,
                            stat_roll_ppm=1_000_000 if int(row['type'])==6 else 1_200_000 if eid in exclusive else 1_150_000,
                            equipment_v2_version=1,wash_schema_version=1)
                pair = row['pl'][6:8]
                wash = dict.fromkeys(['hit','flee','crit','tough'],0)
                if len(pair)==2 and pair[0] in wash and pair[1] in wash and pair[0]!=pair[1]:
                    budget = int(simple['equip_config'][3])*8*gear_cap
                    wash[pair[0]] = budget//2
                    wash[pair[1]] = budget-budget//2
                item['new_4attrs'] = wash
                gear_instances[eid].append(eqid)
            front = ['A_1802_6','A_1801_6','A_1219_6','A_1210_6','A_1206_6','A_1208_6']
            rest = [a for a in heroes if a not in front and int(a.rsplit('_',1)[1])>=5]
            p['team'] = [[hero_instances[a] for a in front],
                         [hero_instances[a] for a in [front[1],front[0],*front[2:]]],
                         [hero_instances[a] for a in rest[:6]]]
            slots = [['E_1011_6','E_1019_6','E_3007_6','E_4007_6','E_5009_6','E_6005_7'],
                     ['E_1011_6','E_1020_6','E_3001_6','E_4007_6','E_5006_6','E_6005_7']]
            slots += [['E_1011_6','E_1019_6','E_3001_6','E_4007_6','E_5009_6','E_6005_7'] for _ in range(4)]
            p['as_equips'] = [[gear_instances[eid][i] for eid in row] for i,row in enumerate(slots)]
            assigned = {i for squad in p['team'] for i in squad}
            reserves = [i for aid,i in hero_instances.items() if i not in assigned and int(aid.rsplit('_',1)[1])>=5]
            attrs['dn'] = {key:[int(simple['dn_lv']),reserves[i]] for i,key in enumerate(sorted(simple['dn'],key=int))}
            p['avatar_soul'] = {aid:100_000 for aid in cfg['avatar'] if aid.startswith('A_1')}
            p['equip_soul'] = dict.fromkeys(cfg['equip'],100_000)
            p['combat_score'] = {'normal':{},'hard':{},'ploy':{}}
            records = p.setdefault('records',{})
            records['pass_battle_gift'] = {'0':[],'1':[],'-1':[]}
            for mode,table,counter,diff in [('normal','battle_main','combat_main','0'),
                                           ('hard','battle_main','combat_main_hard','1'),
                                           ('ploy','battle_ploy','combat_ploy','-1')]:
                records[counter] = {}
                for chapter,row in cfg[table].items():
                    stages = [f'{chapter}_{n}' for n in range(1,int(row['combat'])+1)]
                    p['combat_score'][mode][chapter] = ['1',[3]*len(stages)]
                    records[counter].update(dict.fromkeys(stages,1))
                    records['pass_battle_gift'][diff].append(chapter)
                    if mode=='ploy':
                        p.setdefault('ploy_cids',{})[chapter] = stages
            last = max(cfg['combat_main'],key=lambda cid:tuple(map(int,cid.split('_')[1:])))
            p.update(cid=last,hid=last)
            records['tower_floor'] = int(cfg['battle_ploy']['P_200']['combat'])+1
            p['max_test_save_105'] = dict(version='1.0.5',independent=True,all_stages_three_stars=True,
                                        all_cards_maxed=True,all_equipment_star=8)
            return p,{}

        b.players.atomic_update(uid,seed)
        for n in range(2):
            login = b.call(dict(method='user.login',params=dict(credentials,actionID=f'max105-verify-{n}')))
            assert login['return_code']==0,login
            profile = b.players.profile(uid)
            verify_profile(profile,cfg,roster,heroes,gear)
        assert b.db.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
        manifest = dict(version='1.0.5',account='test105',password='123456',name=profile['name'],
                        cards=len(heroes),hero_cards=sum(int(a.rsplit('_',1)[1])>=5 for a in heroes),
                        card_levels=dict(collections.Counter(h['lv'] for h in profile['avatars'].values())),
                        equipment_families=len(gear),equipment_count=len(gear)*6,equipment_level=gear_cap,
                        equipment_star=8,skills=roster._native_skill_level_cap(),
                        normal_chapters=len(cfg['battle_main']),normal_stages=len(profile['records']['combat_main']),
                        hard_stages=len(profile['records']['combat_main_hard']),
                        activity_stages=len(profile['records']['combat_ploy']),
                        tower_floors=int(cfg['battle_ploy']['P_200']['combat']),
                        energy=energy_state(b.players.profile_raw(uid),b.config,b.clock.now())['current'],
                        coin=profile['coin'],gold=profile['gold'],
                        source_apk_sha256=hashlib.sha256(args.apk.read_bytes()).hexdigest(),
                        source_runtime_config_sha256=runtime['files'][config_key],
                        login_roundtrips_verified=2,all_records_verified=True,original_save_modified=False)
        assert manifest['energy']>=100_000
        b.db.execute('DELETE FROM operation_ledger')
        b.db.commit()
        b.db.execute('VACUUM')
    finally:
        b.db.close()
        b.clock.close()
    raw = database.read_bytes()
    packed = gzip.compress(raw,compresslevel=9,mtime=0)
    compressed = database.with_suffix('.sqlite3.gz')
    compressed.write_bytes(packed)
    assert gzip.decompress(packed)==raw
    manifest.update(database_sha256=hashlib.sha256(raw).hexdigest(),gzip_sha256=hashlib.sha256(packed).hexdigest(),
                    bytes=len(raw),gzip_bytes=len(packed))
    (out/'存档内容与验证记录.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf8')
    print(json.dumps(manifest,ensure_ascii=False))


if __name__=='__main__':
    main()
