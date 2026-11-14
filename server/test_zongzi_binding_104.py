"""The built-in summon keeps its own kit and uses the native rice-dumpling art."""
import json
from pathlib import Path
import struct
import unittest
import xml.etree.ElementTree as ET
import zlib

from battle_engine import ReferenceBattle,base_unit
from gateway import load_game_config

ROOT=Path(__file__).resolve().parents[1]
SUMMON='A_2904100_5'
RESOURCE='A_2014_5'


class ZongziBindingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        cls.hero_ids=sorted(a for a in cls.cfg['avatar'] if a.startswith('A_1212_'))

    def test_authoring_and_runtime_bind_to_native_zongzi(self):
        project=json.loads((ROOT/'config/reconstruction/hero-packs-104/zongzi.json').read_text('utf8'))
        definition=next(h for h in project['data']['heroes']['heroes'] if h['id']=='zongzi')
        self.assertEqual(definition['presentation']['icon'],'builtin:icon/'+RESOURCE)
        self.assertEqual(definition['presentation']['portrait'],'builtin:portrait/'+RESOURCE)
        summon=self.cfg['avatar'][SUMMON]
        self.assertEqual(summon['res'],RESOURCE)
        self.assertEqual(summon['name'],'粽子')
        self.assertEqual(summon['modUnitType'],'summon')
        self.assertEqual(self.cfg['skill'][summon['pl'][10]]['name'],'美味粽子')
        self.assertEqual(self.cfg['avatar']['A_2002_5']['res'],'A_2002_5')
        self.assertEqual(self.cfg['avatar']['A_2020_6']['res'],'A_2020_6')

    def test_summon_bindings_for_each_quality_and_bond_variant(self):
        self.assertIn('A_1212_6',self.hero_ids)
        for aid in self.hero_ids:
            h=self.cfg['avatar'][aid]
            ids={h['pl'][10]}
            for binding in self.cfg['system_simple'].get('bond_skill_variants_104',{}).get(aid,{}).values():
                if binding.get('skill'):ids.add(binding['skill'])
            for sid in ids:
                with self.subTest(aid=aid,sid=sid):
                    actions=[a for a in self.cfg['skill'][sid]['skill'] if a[:2]==['mod_step','summon']]
                    self.assertEqual(len(actions),1)
                    self.assertEqual(actions[0][11],SUMMON)
                    self.assertEqual(self.cfg['avatar'][actions[0][11]]['res'],RESOURCE)

    def test_spawned_unit_keeps_independent_skill_and_capacity(self):
        for aid in self.hero_ids:
            with self.subTest(aid=aid):
                owner=base_unit(self.cfg,aid,60,10,0,.5,False,1)
                target=base_unit(self.cfg,'A_1001_5',60,1,0,.5,False,2)
                battle=ReferenceBattle([owner],[target],config=self.cfg)
                owner=battle.a[0];owner['_team']=battle.a;battle.b[0]['_team']=battle.b
                for _ in range(3):self.assertTrue(battle._apply_native_skill(owner,battle.b))
                pets=battle.a[1:]
                self.assertEqual(len(pets),3)
                self.assertEqual(sum(p['hp']>0 for p in pets),2)
                self.assertEqual(pets[0]['hp'],0)
                pet=pets[-1]
                self.assertEqual(pet['aid'],SUMMON)
                self.assertEqual(self.cfg['avatar'][pet['aid']]['res'],RESOURCE)
                self.assertEqual(pet['slv'],1)
                self.assertEqual(self.cfg['skill'][pet['skill']['skid']]['name'],'美味粽子')
                self.assertFalse(pet['skillB'])
                self.assertEqual(battle._buff(pet,'summon').round,99)

    def test_native_resource_is_available_in_shipped_sprite_and_icon_atlas(self):
        raw=(ROOT/'client/resources/app/assets/swfs/hero_C.swf').read_bytes()
        data=zlib.decompress(raw[8:]) if raw[:3]==b'CWS' else raw[8:]
        offset=(5+(data[0]>>3)*4+7)//8+4
        symbols=set()
        while offset<len(data):
            header,=struct.unpack_from('<H',data,offset);offset+=2
            size=header&63
            if size==63:size,=struct.unpack_from('<I',data,offset);offset+=4
            body=data[offset:offset+size];offset+=size
            if header>>6!=76:continue
            count,=struct.unpack_from('<H',body);index=2
            for _ in range(count):
                index+=2;end=body.index(b'\0',index)
                symbols.add(body[index:end].decode('utf8'));index=end+1
        self.assertIn(RESOURCE,symbols)
        atlas=ET.parse(ROOT/'client/resources/app/assets/textures/1x/icon/hero_C.xml').getroot()
        self.assertTrue(any(t.get('name')==RESOURCE+'_icon0000' for t in atlas))


if __name__=='__main__':unittest.main()
