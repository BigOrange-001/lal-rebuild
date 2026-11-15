import copy
import unittest

from pyamf import remoting
from abyss_relics import apply_relic_config, variant_id
from config_fingerprint import fingerprint_config
from mod_schema import digest
from native_skill_snapshot import _native_skill_snapshot


class RelicConfigurationCostTests(unittest.TestCase):
    def document(self):
        source='S_1001_5'
        return {'cfg':{'avatar':{'A_1001_5':{'pl':[0]*10+[source]}},
                       'system_simple':{},'skill':{source:{
                           'pl':[1,2,300], 'info':'原小技能。',
                           'skill':[['damage',i,1,'x'*200] for i in range(100)],
                           'manualClonePolicy':{'skillId':source,'target':'nearest'},
                           'manualSummonPolicy':{'skillId':source,'maxAlive':2}}}}}

    def test_amf_shares_read_only_actions_without_changing_wire_values(self):
        doc=self.document();apply_relic_config(doc)
        skills=doc['cfg']['skill'];source=skills['S_1001_5']
        sid=variant_id('S_1001_5',20,False);variant=skills[sid]
        self.assertIs(variant['skill'],source['skill'])
        self.assertIs(variant['pl'],source['pl'])
        self.assertEqual(source['manualClonePolicy']['skillId'],'S_1001_5')
        self.assertEqual(variant['manualClonePolicy']['skillId'],sid)
        self.assertEqual(source['manualSummonPolicy']['skillId'],'S_1001_5')
        self.assertEqual(variant['manualSummonPolicy']['skillId'],sid)
        # Model the previous independently deep-copied configuration.
        legacy=copy.deepcopy(doc)
        legacy['cfg']['skill']={k:copy.deepcopy(v) for k,v in skills.items()}
        def encode(value):
            envelope=remoting.Envelope(amfVersion=3)
            envelope['/1']=remoting.Response(value)
            return remoting.encode(envelope,strict=True).getvalue()
        compact,old=encode(doc),encode(legacy)
        self.assertLess(len(compact),len(old)*.5)
        self.assertEqual(remoting.decode(compact)['/1'].body,remoting.decode(old)['/1'].body)
        snapshot=_native_skill_snapshot(doc['cfg'],sid,2)
        snapshot['skills'][0][1]=999
        self.assertEqual(source['skill'][0][1],0)
        clone=copy.deepcopy(doc)
        self.assertIs(clone['cfg']['skill'][sid]['skill'],clone['cfg']['skill']['S_1001_5']['skill'])
        self.assertIsNot(clone['cfg']['skill'][sid]['skill'],source['skill'])

    def test_configuration_digest_covers_sources_overrides_and_removed_fields(self):
        doc=self.document();apply_relic_config(doc)
        before=copy.deepcopy(doc);fingerprint=digest(fingerprint_config(doc))
        self.assertEqual(doc,before)
        independent=copy.deepcopy(doc)
        independent['cfg']['skill']={k:copy.deepcopy(v) for k,v in independent['cfg']['skill'].items()}
        self.assertEqual(fingerprint,digest(fingerprint_config(independent)))
        sid=variant_id('S_1001_5',20,False)
        for change in ('source','override','removed','description'):
            candidate=copy.deepcopy(doc);skills=candidate['cfg']['skill']
            if change=='source':skills['S_1001_5']['pl'][1]=7
            elif change=='override':skills[sid]['pl']=[8,9,10]
            elif change=='removed':del skills[sid]['pl']
            else:skills[sid]['info']+='变更说明'
            self.assertNotEqual(fingerprint,digest(fingerprint_config(candidate)),change)
        ordinary=self.document()
        self.assertIs(fingerprint_config(ordinary)['cfg'],ordinary['cfg'])
        self.assertEqual(digest(ordinary),digest(fingerprint_config(ordinary)))


if __name__=='__main__':unittest.main()
