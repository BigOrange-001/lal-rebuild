"""Twenty-round training-target comparison using maintained native AS skill bodies."""
import copy
import csv
import json
from pathlib import Path
from unittest.mock import patch

from gateway import load_game_config
from battle_engine import base_unit
from roguelite_abyss import hero_record, standard_team, rules
from hero_strength_native_bridge import NativeSkinBattle

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'outputs/ekko-abyss-20-rounds-20261117'


class TrainingBattle(NativeSkinBattle):
    def __init__(self,*args,**kwargs):
        super().__init__(*args,**kwargs)
        self.curve=[]
        self.positions=[]

    def _run_unit_turn_base(self,attacker,sides,side):
        if side==1:
            return super()._run_unit_turn_base(attacker,sides,side)
        # The target takes turns for status expiry but never attacks or moves.
        attacker['_team']=sides[side]
        self.turn_start(attacker)
        self._tick_buffs(attacker)
        total=self.statistics[(1,self.a[0]['_owner_token'])]['damage']
        self.curve.append({'round':self.round_index+1,'damage':total-(self.curve[-1]['cumulative'] if self.curve else 0),'cumulative':total})
        self.positions.append(self.a[0]['pos'])
        return True


def compare(cfg,label,level,before):
    config=copy.deepcopy(cfg)
    if before:
        rules(config).update(skin_stat_multiplier=1,skin_skill_level=5,skin_skill_level_max=10)
    heroes={aid:hero_record(aid,cfg=config) for aid in ('A_1140_6','A_1002_5','A_1003_5')}
    heroes['A_1140_6']['slv']=level
    owner=standard_team(config,heroes,[[a,i%3,.5] for i,a in enumerate(heroes)])[0]
    assert not owner['bonds_104'],'training comparison must not activate a hero bond'
    target=base_unit(config,'A_1001_5',99,1,line=0,pos=.5,team=2)
    target.update(hp=10**12,hp_max=10**12,ap=0,de_ph=0,de_ma=0,skill=None,leader_skill=None,skillB=None,book_skill=None,
                  new_4attrs={'hit':0,'flee':0,'crit':0,'tough':0},pos=owner['pos']-int(config['system_simple']['battle'][2]))
    target['tpl'][0]=owner['tpl'][0]  # same sign: no sign advantage
    battle=TrainingBattle([owner],[target],config=config,seed=20261117,max_rounds=20)
    with patch('manual_ability_sim.miss_chance',return_value=0),patch('manual_ability_sim.crit_chance',return_value=0):
        result=battle.run()
    assert result['rounds']==20 and len(battle.curve)==20
    assert all(p==owner['pos'] for p in battle.positions),(owner['pos'],battle.positions,battle._get_range(battle.a[0]))
    assert not battle._js_contexts
    return {'label':label,'skill_level':owner['slv'],'attack':owner['ap'],'health':owner['hp_max'],
            'casts':battle.manual_casts,'curve':battle.curve}


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
    cases=[compare(cfg,'初始·调整前（5级）',5,True),compare(cfg,'初始·调整后（3级）',3,False),
           compare(cfg,'休整·调整前（10级）',10,True),compare(cfg,'休整·调整后（6级）',6,False)]
    assumptions={'hero':'艾克 A_1140_6','mode':'肉鸽模式99级标准化面板','rounds':20,'captain':True,
                 'target':'单个不还手、不移动、双防为0、同印记、无限生命的训练靶',
                 'accuracy':'必命中、不暴击','equipment':False,'relics':False,'hero_bonds':False,
                 'movement':'初始即在攻击范围内；20回合中艾克位置不变',
                 'engine':'NativeSkinBattle：语法转换后执行维护中的ActionScript技能方法；通用结算使用离线模型',
                 'limit':'此为受控站桩测算，未进行手机实战验证。队长技和被动按原触发时机纳入，敌方无伤害故无受伤回溯治疗。'}
    for before,after in ((cases[0],cases[1]),(cases[2],cases[3])):
        assert after['attack']==int(before['attack']*.66)
        assert before['casts']==after['casts'],'skill-level adjustment must preserve cast timing'
        assert after['curve'][-1]['cumulative']<=before['curve'][-1]['cumulative']*.66
    (OUT/'ekko_20_rounds.json').write_text(json.dumps({'assumptions':assumptions,'cases':cases},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    with (OUT/'艾克20回合输出对比.csv').open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.writer(f)
        writer.writerow(['回合']+[c['label']+suffix for c in cases for suffix in ('当回合伤害','累计伤害')])
        for i in range(20):writer.writerow([i+1]+[c['curve'][i][key] for c in cases for key in ('damage','cumulative')])
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.font_manager import FontProperties
    font=FontProperties(fname='C:/Windows/Fonts/msyh.ttc')
    plt.rcParams['font.family']=font.get_name()
    plt.rcParams['axes.unicode_minus']=False
    fig,axs=plt.subplots(1,2,figsize=(15,6),layout='constrained')
    colors=['#727E94','#D65330','#314E79','#168477']
    for case,color in zip(cases,colors):
        x=[r['round'] for r in case['curve']]
        for ax,key in zip(axs,('cumulative','damage')):
            ax.plot(x,[r[key] for r in case['curve']],color=color,label=case['label'],linewidth=2,
                    linestyle='--' if '调整前' in case['label'] else '-',marker='o',markersize=3)
    for ax,title in zip(axs,('20回合累计输出','每回合输出')):
        ax.set_title(title,fontproperties=font,fontsize=15)
        ax.set_xlabel('回合',fontproperties=font);ax.set_ylabel('伤害',fontproperties=font)
        ax.set_xticks(range(1,21));ax.grid(alpha=.2)
        ax.spines[['top','right']].set_visible(False)
        ax.legend(prop=font,fontsize=10,frameon=False)
        ax.ticklabel_format(axis='y',style='plain',useOffset=False)
    fig.suptitle('艾克 · 肉鸽皮肤卡调整前后站桩输出',fontproperties=font,fontsize=18)
    fig.savefig(OUT/'艾克20回合输出曲线.png',dpi=150)
    fig.savefig(OUT/'艾克20回合输出曲线.svg')
    plt.close(fig)
    summary=[{'label':c['label'],'attack':c['attack'],'damage_20':c['curve'][-1]['cumulative'],'mean_per_round':round(c['curve'][-1]['cumulative']/20,1),'casts':c['casts']} for c in cases]
    print(json.dumps(summary,ensure_ascii=False))


if __name__=='__main__':main()
