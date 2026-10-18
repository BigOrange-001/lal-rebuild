"""Execute the shipped AS Mod selection, configuration and loader boundaries.

The Node harness uses the actual method bodies with Flash transport/bitmap
stubs. It covers save switching and failure sequencing, not GPU/native pickers.
"""
import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

from test_avatar_passive import method_body

ROOT = Path(__file__).resolve().parents[1]
STAGES = ROOT / 'client/src/stages'
NODE = shutil.which('node')


def install(file, name, parameters='', receiver='unit'):
    body = method_body((STAGES / file).read_text('utf8'), name)
    body = re.sub(r'for each\s*\(([^)]+) in ([^)]+)\)', r'for (\1 of \2)', body)
    body = re.sub(r'catch\((\w+):Error\)', r'catch(\1)', body)
    body = re.sub(r'function\(([^)]*)\)',
                  lambda match: 'function(' + re.sub(r':\s*[\w.]+', '', match.group(1)) + ')', body)
    body = re.sub(r'([\w.$]+) is Array', r'Array.isArray(\1)', body)
    body = body.replace('param1 is Avatar', 'param1 instanceof Avatar')
    body = body.replace('issue is String', 'typeof issue === "string"')
    body = body.replace('item is String', 'typeof item === "string"')
    body = body.replace('change is String', 'typeof change === "string"')
    return f'{receiver}.{name}=function({parameters}){{with(this){{{body}\n}}}};\n'


@unittest.skipUnless(NODE, 'Node is needed for the native ActionScript harness')
class ModClientTests(unittest.TestCase):
    def run_js(self, text):
        result = subprocess.run([NODE, '-e', text], encoding='utf8', capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_overrides_keep_explicit_false_and_new_keys_default_on(self):
        script = 'const unit={};\n'
        script += install('151_PanelHelpSetting.as', 'modToggleValue', 'explicit,inherited,key')
        script += install('151_PanelHelpSetting.as', 'mergedModDefaults', 'base,overrides')
        script += '''const inherited=unit.mergedModDefaults({normal:true,advanced:true},{normal:false});
console.log(JSON.stringify([unit.modToggleValue({},inherited,'normal'),
 unit.modToggleValue({normal:true},inherited,'normal'),
 unit.modToggleValue({},inherited,'new_channel')]));'''
        self.assertEqual(self.run_js(script), [False, True, True])

    def test_version_switch_copies_manual_choices_without_mutating_old_version(self):
        script = '''const unit={mModSelections:[{packageId:'p',version:'1.0.0',contentDigest:'a',enabled:true,
channels:{normal:false},patchScopes:{arenaEnemy:false},heroes:{hero:{channels:{shop:false}}}}]};\n'''
        script += install('151_PanelHelpSetting.as', 'selectedMod', 'row,create=false')
        script += '''const value=unit.selectedMod({packageId:'p',version:'2.0.0',contentDigest:'b'},true);
value.channels.normal=true;
console.log(JSON.stringify({newScope:value.patchScopes.arenaEnemy,newShop:value.heroes.hero.channels.shop,
oldNormal:unit.mModSelections[0].channels.normal,enabled:value.enabled,version:value.version}));'''
        self.assertEqual(self.run_js(script), {'newScope': False, 'newShop': False,
                                             'oldNormal': False, 'enabled': False, 'version': '2.0.0'})

    def test_configuration_replaces_previous_save_and_clears_parsed_managers(self):
        script = '''const unit={},GlobalData={$mConfig:{avatar:{old:{}}},$mConfig_avatar:{old:{}}};
let resets=0;const manager={clear(){resets++;}};
const AvatarManager=manager,SkillSetManager=manager,EffectManager=manager,EquipManager=manager;
'''
        script += install('045_GlobalFunction.as', 'applyModConfig', 'envelope')
        script += '''const ok=unit.applyModConfig({uid:'B',digest:'d',cfg:{avatar:{base:{}},skill:{},effect:{},system_simple:{}}});
console.log(JSON.stringify({ok,keys:Object.keys(GlobalData.$mConfig_avatar),resets}));'''
        self.assertEqual(self.run_js(script), {'ok': True, 'keys': ['base'], 'resets': 4})

    def test_scoped_alias_preserves_identity_channels_and_instance_suffix(self):
        script = '''const unit={$modRuntime:{aliasBaseIds:{A_160001_5:'A_1001_5'},
scopedAvatarIds:{arenaEnemy:{A_1001_5:'A_160001_5'},summoned:{A_1001_5:'A_160002_5'}},
heroes:{A_1001_5:{available:true,channels:{'usage.destiny':false}},A_180001_5:{available:false}}}};
'''
        for name, params in [('baseModHeroId', 'id'), ('modDefinitionId', 'id,scope'),
                             ('canonicalModInstanceId', 'id'), ('modChannelAllowed', 'id,channel')]:
            script += install('001_GlobalData.as', name, params)
        script += '''console.log(JSON.stringify([unit.canonicalModInstanceId('A_160001_5-7'),
unit.modDefinitionId('A_160001_5','summoned'),unit.modChannelAllowed('A_160001_5','usage.destiny'),
unit.modChannelAllowed('A_180001_5|9','usage.friend_assist'),unit.modChannelAllowed('A_1002_5','usage.destiny')]));'''
        self.assertEqual(self.run_js(script), ['A_1001_5-7', 'A_160002_5', False, False, True])

    def loader_harness(self):
        script = '''const pending=[],timers=new Map();let serial=0,decodes=0,codeImports=[];
const setTimeout=fn=>{timers.set(++serial,fn);return serial;},clearTimeout=id=>timers.delete(id);
const MainConfig={$SERVER_ADDRESS:'http://127.0.0.1:8080'};
const flash={events:{Event:{COMPLETE:'complete'}}},IOErrorEvent={IO_ERROR:'io'},SecurityErrorEvent={SECURITY_ERROR:'security'};
const URLLoaderDataFormat={BINARY:'binary'};
class URLRequest{constructor(url){this.url=url;}}
class URLLoader{constructor(){this.events={};}addEventListener(key,fn){this.events[key]=fn;}load(request){pending.push(this);}}
class Bitmap{constructor(){this.bitmapData={width:32,height:32,clone(){return {width:32,height:32,dispose(){}};}};}}
class LoaderContext{}
class Loader{constructor(){this.events={};this.contentLoaderInfo={addEventListener:(key,fn)=>this.events[key]=fn};this.content=new Bitmap();}
loadBytes(bytes,context){decodes++;codeImports.push(context.allowCodeImport);this.events.complete({});}unloadAndStop(){}}
const Texture={fromBitmapData:()=>({root:{}})};
const unit={$modGeneration:0,$modAssets:[],$modBitmaps:[],$modRuntime:{},$modReady:true,
$modUid:'',$modRevision:-1,$modDigest:'',$modError:'',
$assetManager:{addTexture(){},removeTexture(){},addSound(){},removeSound(){}}};
'''
        for name, params in [('resetModResources', ''), ('loadModResources', 'envelope,done')]:
            script += install('001_GlobalData.as', name, params)
        script += '''const manifest=uid=>({uid,revision:1,digest:'x',cfg:{},mod_runtime:{assets:[{
alias:'MOD_portrait',kind:'image',contentDigest:'a'.repeat(64),path:'assets/portrait.png'}]}});
'''
        return script

    def test_late_resource_callback_cannot_write_into_another_save(self):
        script = self.loader_harness() + '''let a=[],b=[];
unit.loadModResources(manifest('A'),value=>a.push(value));
unit.loadModResources({uid:'B',revision:1,digest:'b',cfg:{},mod_runtime:{}},value=>b.push(value));
pending[0].data=new Uint8Array([137,80,78,71]);pending[0].events.complete({});
console.log(JSON.stringify({a,b,uid:unit.$modUid,ready:unit.$modReady,decodes}));'''
        self.assertEqual(self.run_js(script), {'a': [], 'b': [True], 'uid': 'B', 'ready': True, 'decodes': 0})

    def test_image_decoder_disallows_code_and_timeout_cannot_become_success(self):
        script = self.loader_harness() + '''let replies=[];
unit.loadModResources(manifest('A'),value=>replies.push(value));
pending[0].data=new Uint8Array([137,80,78,71]);pending[0].events.complete({});
let first={replies:[...replies],ready:unit.$modReady,codeImports:[...codeImports]};replies=[];
unit.loadModResources(manifest('B'),value=>replies.push(value));
[...timers.values()].at(-1)();pending.at(-1).data=new Uint8Array([137,80,78,71]);pending.at(-1).events.complete({});
console.log(JSON.stringify({first,replies,ready:unit.$modReady,decodes}));'''
        self.assertEqual(self.run_js(script), {'first': {'replies': [True], 'ready': True, 'codeImports': [False]},
                                             'replies': [False], 'ready': False, 'decodes': 1})

    def test_disguised_swf_never_reaches_flash_loader(self):
        script = self.loader_harness() + '''let replies=[];unit.loadModResources(manifest('A'),v=>replies.push(v));
pending[0].data=new Uint8Array([70,87,83,9]);pending[0].events.complete({});
console.log(JSON.stringify({replies,decodes,ready:unit.$modReady}));'''
        self.assertEqual(self.run_js(script), {'replies': [False], 'decodes': 0, 'ready': False})

    def test_gpu_upload_failure_is_reported_without_a_success_callback(self):
        script = self.loader_harness() + '''let replies=[];
Texture.fromBitmapData=()=>{throw new Error('GPU exhausted');};
unit.loadModResources(manifest('A'),v=>replies.push(v));
pending[0].data=new Uint8Array([137,80,78,71]);pending[0].events.complete({});
console.log(JSON.stringify({replies,ready:unit.$modReady,message:unit.$modError}));'''
        result = self.run_js(script)
        self.assertEqual((result['replies'], result['ready']), ([False], False))
        self.assertIn('图像上传失败', result['message'])

    def test_preview_commit_failure_retry_and_relogin_keep_edit_state(self):
        script = '''const sent=[],timers=[];let relogins=0;
const GlobalData={$modReady:true,isCurrentProfileSyncEnvelope:()=>true};
const GlobalFunction={quitGame(){relogins++;}};
const int=Math.trunc,setTimeout=fn=>timers.push(fn);
const SendAndSelect={$uid:'A',sendAndSelectService(method,params,reply){sent.push({method,params,reply});}};
const button={removeEventListener(){},addEventListener(){}};
const unit={mModBusy:false,mModOwner:'A',mModInfo:{revision:2},mModDirty:true,mModRequestId:'',
mModSelections:[{packageId:'p',channels:{normal:false}}],mModStatus:{text:''},modAlive:()=>true,
beginPreviewPages(){},finishPreviewPages(){},beginModRows(){},modText(){},modRow(){},onModRow(){},mModScroll:{numChildren:1,getChildAt:()=>button}};
'''
        for name, params in [('modReplyMatches', 'reply,owner,alive'), ('formatModIssue', 'issue'),
                             ('previewMods', 'event'), ('commitMods', 'event'), ('onModError', 'event')]:
            script += install('151_PanelHelpSetting.as', name, params)
        script += '''unit.previewMods(null);const before=sent.length;
sent[0].reply({return_code:0,data:{valid:true,planDigest:'plan1',changes:[],errors:[],warnings:[]}});
unit.commitMods(null);const request=sent[1].params.requestId;
unit.onModError({data:{method:'user.mods_apply',data:{message:'pending battle'}}});
const failure={dirty:unit.mModDirty,busy:unit.mModBusy,selections:JSON.stringify(unit.mModSelections)};
unit.commitMods(null);const same=sent[2].params.requestId===request;
sent[2].reply({return_code:0,data:{revision:3,digest:'new',reloginRequired:true}});
const beforeLogin=relogins;timers[0]();
console.log(JSON.stringify({before,methods:sent.map(x=>x.method),failure,same,beforeLogin,relogins,
ready:GlobalData.$modReady,dirty:unit.mModDirty,plan:sent[2].params.planDigest,revision:sent[2].params.expectedRevision}));'''
        result = self.run_js(script)
        self.assertEqual(result['methods'], ['user.mods_plan', 'user.mods_apply', 'user.mods_apply'])
        self.assertEqual(result['failure'], {'dirty': True, 'busy': False,
                                            'selections': '[{"packageId":"p","channels":{"normal":false}}]'})
        self.assertTrue(result['same'])
        self.assertEqual((result['beforeLogin'], result['relogins'], result['ready'], result['dirty']),
                         (0, 1, False, False))
        self.assertEqual((result['plan'], result['revision']), ('plan1', 2))

    def test_missing_detail_offers_reclaim_and_never_opens_progression_panel(self):
        script = '''const sent=[];let shown=null,panels=0;function Avatar(){}
const GlobalData={$modRuntime:{heroes:{A_180001_5:{name:'Lost Hero'}}},isMissingModHero:()=>true,
$mGameClassObject:{mLayoutUICenter:{showPanel(){panels++;}}}};
const SendAndSelect={sendAndSelectService(method,params,callback){sent.push({method,params});}};
const unit={functionNull(){},popAlert(title,text,actions){shown={title,text,actions};},popMsg(){}};
'''
        script += install('045_GlobalFunction.as', 'setDetaiAvatar', 'param1,param2=false')
        script += '''unit.setDetaiAvatar({id:'A_180001_5|12'});shown.actions.ok();
console.log(JSON.stringify({title:shown.title,button:shown.actions.okUI,panels,sent}));'''
        self.assertEqual(self.run_js(script), {'title': '内容缺失', 'button': '取回装备', 'panels': 0,
                                             'sent': [{'method': 'user.mods_reclaim_equipment',
                                                       'params': {'avatarId': 'A_180001_5|12'}}]})

    def test_manual_pve_uses_authoritative_context_snapshots_only_for_mods(self):
        script = '''const GlobalData={$isPVE:true,$isExploration:false,$tempPVE_type:'',$currentGuide:false,$modRuntime:{}};
const GameMapLayer={isAuto:false},SoundManager={getOnlyExample:()=>({playSound(){}})};
const GlobalFunction={isVersionedProfileReceipt:()=>false};
const unit={re:null,randomSeed:0,friendAvatar:null,firstTeam:0,isLoad:false,origin:0,random:0,ready:0,
initByOrgin(){this.origin++;},addRandom(){this.random++;},checkOrginTeam(){},readyFight(){this.ready++;}};
'''
        script += install('083_GameMap.as', 'reSend', 'param1=null')
        script += '''unit.reSend({data:{seed:1,sign:0}});const base={origin:unit.origin,random:unit.random,ready:unit.ready};
unit.re=null;GlobalData.$modRuntime={digest:'active'};unit.reSend({data:{seed:2,sign:0}});
console.log(JSON.stringify({base,mod:{origin:unit.origin,random:unit.random,ready:unit.ready}}));'''
        self.assertEqual(self.run_js(script), {'base': {'origin': 0, 'random': 1, 'ready': 1},
                                             'mod': {'origin': 1, 'random': 1, 'ready': 2}})

    def test_hero_portrait_lookup_uses_registered_presentation_and_missing_resource(self):
        script = '''const GlobalData={baseModHeroId:id=>id,$modRuntime:{heroes:{A_180001_5:{},A_180002_5:{}}},
$mConfig_avatar:{A_1001_5:{res:'legacy-alias'},A_180001_5:{res:'MOD_portrait'},A_180002_5:{res:'__modMissingHero'}}};
const unit={createImage:name=>name};
'''
        script += install('045_GlobalFunction.as', 'getAvatarUI', 'param1="A_1001_2"')
        script += '''console.log(JSON.stringify([unit.getAvatarUI('A_1001_5'),unit.getAvatarUI('A_180001_5|7'),unit.getAvatarUI('A_180002_5')]));'''
        self.assertEqual(self.run_js(script), ['A_1001_5', 'MOD_portrait', '__modMissingHero'])

    def test_corrupt_inbox_rows_are_display_only(self):
        script = '''const actions=[],texts=[],labels=[];const unit={mModSelections:[],mModPackage:-1,
modAlive:()=>true,beginModRows(){},modText:text=>texts.push(text),modRow:(text,data)=>{actions.push(data);labels.push(text);},
mModInfo:{packages:[{packageId:'',version:'0.0.0',contentDigest:'',kind:'error',status:'corrupt',name:'broken.heropack',reason:'bad JSON'},
{packageId:'good',version:'1.0.0',contentDigest:'abc',kind:'new',status:'installed',name:'Good',author:'A'}],errors:[],missing:[]}};
'''
        for name, params in [('selectedMod', 'row,create=false'), ('modStatusName', 'status,enabled'),
                             ('renderModList', '')]:
            script += install('151_PanelHelpSetting.as', name, params)
        script += '''unit.renderModList();console.log(JSON.stringify({actions,texts,labels,selected:unit.mModSelections}));'''
        result = self.run_js(script)
        self.assertEqual(result['actions'], [{'action': 'enable', 'package': 1}, {'action': 'details', 'package': 1},
                                             {'action': 'backupExport'}, {'action': 'backupImport'}, {'action': 'backupPrevious'}])
        self.assertEqual(result['selected'], [])
        self.assertIn('bad JSON', result['texts'])
        self.assertEqual(result['labels'][0], '当前存档：已关闭此包（点击启用）')

    def test_large_global_uninstall_uses_scrollable_preview_then_explicit_commit(self):
        script = '''const sent=[],texts=[];let confirm=null;
const button={removeEventListener(){},addEventListener(event,callback){confirm=callback;}};
const SendAndSelect={sendAndSelectService(method,params,callback){sent.push({method,params,callback});}};
const unit={mBuildingPreview:false,mModDirty:false,mModBusy:false,mModPackage:0,mModOwner:'A',mModStatus:{text:''},
mModInfo:{packages:[{packageId:'p',version:'1.0.0',contentDigest:'digest'}]},
modAlive:()=>true,modReplyMatches:()=>true,beginPreviewPages(){},finishPreviewPages(label,callback){confirm=callback;},beginModRows(){},modText:text=>texts.push(text),modRow(){},onModRow(){},
mModScroll:{numChildren:1,getChildAt:()=>button}};
'''
        script += install('151_PanelHelpSetting.as', 'formatModIssue', 'issue')
        script += install('151_PanelHelpSetting.as', 'modWrappedText', 'text,color=16777215')
        script += install('151_PanelHelpSetting.as', 'modPreviewValue', 'label,value,color=16777215')
        script += install('151_PanelHelpSetting.as', 'renderModChange', 'change')
        script += install('151_PanelHelpSetting.as', 'previewUninstall')
        script += '''unit.previewUninstall();sent[0].callback({data:{valid:true,affectedSaves:200,planDigest:'token',
changes:Array.from({length:150},(_,i)=>({message:'Save '+i})),errors:[]}});
const previewCalls=sent.length;confirm(null);
console.log(JSON.stringify({previewCalls,textRows:texts.length,methods:sent.map(x=>x.method),token:sent[1].params.planDigest}));'''
        self.assertEqual(self.run_js(script), {'previewCalls': 1, 'textRows': 152,
                                             'methods': ['user.mods_uninstall_plan', 'user.mods_uninstall'],
                                             'token': 'token'})

    def test_modal_origin_and_footer_stay_on_stage_when_settings_parent_is_offset(self):
        script = '''class Point{constructor(x,y){this.x=x;this.y=y;}}
class Sprite{constructor(){this.children=[];}addChild(child){this.children.push(child);}}
class Quad{constructor(width,height,color){Object.assign(this,{width,height,color});}}
class ScrollContainer{}
const GlobalData={$mStageWidth:640,$mStageHeight:960,$userData:{name:'Test'}};
const GlobalTextStyle={getTextField:()=>({})};
const SendAndSelect={$uid:'A',$SendServiceAMFDispatcher:{addEventListener(){}}};
let offset=0,footers=[];
const unit={mDisposed:false,mModOwner:'',mModShield:null,mModView:null,mModScroll:null,mModStatus:null,
globalToLocal:p=>new Point(p.x,p.y-offset),addChild(){},requestModInfo(){},onModError(){},
modFooter:(label,x,y)=>footers.push({label,x,y}),closeModManager(){},importMod(){},scanMods(){},previewMods(){}};
'''
        script += install('151_PanelHelpSetting.as', 'openModManager', 'event')
        script += '''const results=[];for(offset of [0,140,280]){unit.mModView=null;footers=[];unit.openModManager(null);
const modal=unit.mModView;results.push({top:modal.y+offset,bottom:modal.y+offset+modal.children[0].height,
footerBottom:modal.y+offset+footers.at(-1).y+48,shieldTop:unit.mModShield.y+offset,color:modal.children[1].color});}
console.log(JSON.stringify(results));'''
        self.assertEqual(self.run_js(script), [{'top': 90, 'bottom': 870, 'footerBottom': 853,
                                               'shieldTop': 0, 'color': 0x2B2018}] * 3)


    def test_patch_preview_expands_nested_values_scope_and_source_without_clipping(self):
        script = "const lines=[];const unit={mBuildingPreview:false,modText:(text,color,height)=>lines.push({text,height})};\n"
        script += install('151_PanelHelpSetting.as', 'modWrappedText', 'text,color=16777215')
        script += install('151_PanelHelpSetting.as', 'modPreviewValue', 'label,value,color=16777215')
        script += install('151_PanelHelpSetting.as', 'renderModChange', 'change')
        script += '''unit.renderModChange({message:'A_1001_5',packageId:'package',patchId:'recover',target:'A_1001_5',scope:'owned',
changes:[{path:'skills.normal',before:{name:'旧技能',ratio:0,voice:null},after:{name:'新技能'.repeat(100),enabled:false}}],
sourceNotes:{origin:'回忆资料',review:'已核对'}});
console.log(JSON.stringify({text:lines.map(x=>x.text).join(''),max:Math.max(...lines.map(x=>x.text.length)),minHeight:Math.min(...lines.map(x=>x.height))}));'''
        result = self.run_js(script)
        for text in ['scope：owned', 'target：A_1001_5', 'skills.normal', '原值：', '新值：', '旧技能',
                     '新技能' * 100, '"ratio": 0', '"voice": null', '"enabled": false', '来源说明：', '回忆资料']:
            self.assertIn(text, result['text'])
        self.assertLessEqual(result['max'], 28)
        self.assertGreaterEqual(result['minHeight'], 26)

    def test_backup_native_file_write_invalid_import_cancel_and_owner_guard(self):
        script = '''let writes=[],reads=0,previews=0;
const flash={events:{Event:{SELECT:'select',CANCEL:'cancel'}}};const IOErrorEvent={IO_ERROR:'ioError'};const FileMode={WRITE:'write',READ:'read'};
class FileStream{open(file,mode){this.mode=mode;}writeUTFBytes(text){writes.push(JSON.parse(text));}close(){}readUTFBytes(){reads++;return 'broken JSON';}}
const file={size:12,removeEventListener(){}};
const unit={mModBusy:true,mModOwner:'A',mBackupOwner:'A',mBackupFile:file,mBackupMode:'write',
mBackupValue:{schema:'lal-mod-backup-v1',state:{selections:[]},digest:'sealed'},mModStatus:{text:''},
modAlive:()=>true,onBackupSelected(){},onBackupCancelled(){},previewModRestore(){previews++;}};
'''
        for name, params in [('clearBackupPicker', ''), ('onBackupSelected', 'event'), ('onBackupCancelled', 'event')]:
            script += install('151_PanelHelpSetting.as', name, params)
        script += '''unit.mModOwner='B';unit.onBackupSelected({currentTarget:file});const blocked=writes.length;
unit.mModOwner='A';unit.onBackupSelected({currentTarget:file});
const saved={busy:unit.mModBusy,cleared:unit.mBackupFile===null};
Object.assign(unit,{mModBusy:true,mBackupOwner:'A',mBackupFile:file,mBackupMode:'read'});
unit.onBackupSelected({currentTarget:file});const failed={busy:unit.mModBusy,text:unit.mModStatus.text};
Object.assign(unit,{mModBusy:true,mBackupOwner:'A',mBackupFile:file,mBackupMode:'read'});
unit.onBackupCancelled({currentTarget:file});
console.log(JSON.stringify({blocked,writes,saved,failed,reads,previews,cancelBusy:unit.mModBusy}));'''
        result = self.run_js(script)
        self.assertEqual(result['blocked'], 0)
        self.assertEqual(result['writes'], [{'schema': 'lal-mod-backup-v1', 'state': {'selections': []}, 'digest': 'sealed'}])
        self.assertEqual(result['saved'], {'busy': False, 'cleared': True})
        self.assertFalse(result['failed']['busy'])
        self.assertIn('当前设置未改变', result['failed']['text'])
        self.assertEqual((result['reads'], result['previews'], result['cancelBusy']), (1, 0, False))

    def test_previous_backup_restore_requires_preview_confirmation_and_retry_keeps_key(self):
        script = '''const sent=[],lines=[],timers=[];let relogins=0;
const GlobalData={$modReady:true,isCurrentProfileSyncEnvelope:()=>true};
const GlobalFunction={quitGame(){relogins++;}};const int=Math.trunc,setTimeout=fn=>timers.push(fn);
const SendAndSelect={$uid:'A',sendAndSelectService(method,params,reply){sent.push({method,params,reply});}};
const button={removeEventListener(){},addEventListener(){}};
const unit={mModBusy:false,mModOwner:'A',mModInfo:{revision:4},mModDirty:true,mModStatus:{text:''},
mRestoreRequestId:'',mRestoreBackup:null,mRestorePlan:null,mModPreview:false,mBackupEpoch:0,mBuildingPreview:false,
modAlive:()=>true,beginPreviewPages(){},finishPreviewPages(){},beginModRows(){},modText:text=>lines.push(text),modRow(){},onModRow(){},
mModScroll:{numChildren:1,getChildAt:()=>button},openBackupPicker(){throw Error('Unexpected picker');}};
'''
        for name, params in [('modReplyMatches', 'reply,owner,alive'), ('formatModIssue', 'issue'),
                             ('modWrappedText', 'text,color=16777215'), ('modPreviewValue', 'label,value,color=16777215'), ('renderModChange', 'change'),
                             ('beginBackupAction', 'action'), ('previewModRestore', 'backup'),
                             ('commitModRestore', 'event'), ('onModError', 'event')]:
            script += install('151_PanelHelpSetting.as', name, params)
        script += '''unit.beginBackupAction('backupPrevious');const dirtyBlocked=sent.length;
unit.mModDirty=false;unit.beginBackupAction('backupPrevious');
const backup={schema:'lal-mod-backup-v1',state:{selections:[]},identityMap:{},digest:'sealed'};
sent[0].reply({return_code:0,data:backup});const beforePlanCommit=sent.length;
sent[1].reply({return_code:0,data:{valid:true,revision:4,planDigest:'restore-plan',changes:['恢复清单'],warnings:[{message:'缺少包保持内容缺失'}]}});
const beforeConfirm=sent.length;unit.commitModRestore(null);const firstKey=sent[2].params.requestId;
unit.onModError({data:{method:'user.mods_restore',data:{message:'pending'}}});
unit.commitModRestore(null);const retryKey=sent[3].params.requestId;
sent[3].reply({return_code:0,data:{reloginRequired:true}});timers[0]();
console.log(JSON.stringify({dirtyBlocked,beforePlanCommit,beforeConfirm,methods:sent.map(x=>x.method),
previous:sent[0].params.previous,backup:sent[3].params.backup,plan:sent[3].params.planDigest,
revision:sent[3].params.expectedRevision,same:firstKey===retryKey,ready:GlobalData.$modReady,relogins,lines:lines.join('')}));'''
        result = self.run_js(script)
        self.assertEqual((result['dirtyBlocked'], result['beforePlanCommit'], result['beforeConfirm']), (0, 2, 2))
        self.assertEqual(result['methods'], ['user.mods_backup', 'user.mods_restore_plan', 'user.mods_restore', 'user.mods_restore'])
        self.assertTrue(result['previous'])
        self.assertEqual(result['backup']['digest'], 'sealed')
        self.assertEqual((result['plan'], result['revision']), ('restore-plan', 4))
        self.assertEqual((result['same'], result['ready'], result['relogins']), (True, False, 1))
        self.assertIn('缺少包保持内容缺失', result['lines'])
        self.assertIn('不会回滚卡牌', result['lines'])


    def test_large_preview_builds_only_sixty_rows_per_page_and_keeps_full_values(self):
        script = '''const int=Math.trunc;
class LOL_Scale9Button{constructor(label){this.label=label;this.events={};}addEventListener(e,fn){this.events[e]=fn;}removeEventListener(e){delete this.events[e];}}
const GlobalTextStyle={getTextField:(text,size,color,align,width,height)=>({text,height})};
const scroll={children:[],addChild(c){this.children.push(c);},removeChildren(){this.children=[];},
get numChildren(){return this.children.length;},getChildAt(i){return this.children[i];}};
const unit={mModScroll:scroll,mModRows:[],mModY:0,mModBusy:false,mModPreview:true,mPreviewPage:0,
mPreviewBlocks:[],mPreviewLineCount:0,mBuildingPreview:false,mPreviewConfirm:null,mPreviewConfirmLabel:'',modAlive:()=>true};
'''
        for name, params in [('beginModRows', ''), ('modText', 'text,color=16777215,height=48'),
                             ('modRow', 'label,data,enabled=true'), ('onModRow', 'event'),
                             ('previewLineCount', 'text'), ('beginPreviewPages', ''),
                             ('finishPreviewPages', 'label,confirm'), ('renderModPreviewPage', ''),
                             ('modWrappedText', 'text,color=16777215'), ('modPreviewValue', 'label,value,color=16777215')]:
            script += install('151_PanelHelpSetting.as', name, params)
        script += '''const value={name:'技能'.repeat(1000),tail:'FINAL_SENTINEL'};
unit.beginPreviewPages();unit.modWrappedText(Array.from({length:5000},(_,i)=>'line'+i).join('\\n'));
unit.modPreviewValue('新值：',value);unit.finishPreviewPages('确认恢复',()=>{});
const first={nodes:scroll.numChildren,text:scroll.children.map(x=>x.text||x.label).join(''),blocks:unit.mPreviewBlocks.length};
unit.onModRow({currentTarget:{name:'modrow_0'}});const nextPage=unit.mPreviewPage,middleNodes=scroll.numChildren;
unit.mPreviewPage=Math.ceil(unit.mPreviewLineCount/60)-1;unit.renderModPreviewPage();
console.log(JSON.stringify({first,nextPage,middleNodes,lastNodes:scroll.numChildren,last:scroll.children.map(x=>x.text||x.label).join(''),
reference:unit.mPreviewBlocks[1].value===value,retainedJSON:unit.mPreviewBlocks[1].hasOwnProperty('text'),pages:Math.ceil(unit.mPreviewLineCount/60)}));'''
        result = self.run_js(script)
        self.assertLessEqual(result['first']['nodes'], 64)
        self.assertLessEqual(result['middleNodes'], 64)
        self.assertLessEqual(result['lastNodes'], 64)
        self.assertEqual((result['first']['blocks'], result['nextPage']), (2, 1))
        self.assertIn('line0', result['first']['text'])
        self.assertNotIn('line60', result['first']['text'])
        self.assertIn('FINAL_SENTINEL', result['last'])
        self.assertTrue(result['reference'])
        self.assertFalse(result['retainedJSON'])
        self.assertGreater(result['pages'], 80)


if __name__ == '__main__':
    unittest.main()
