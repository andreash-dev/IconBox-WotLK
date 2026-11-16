-- Run from the repository root: lua tests/test_conflict.lua
local f=assert(io.open('IconBox/IconBox.lua') or io.open('IconBox.lua'));local source=f:read('*a');f:close()
local code=assert(source:match('(local conflictPrompted = false.-)local function Scan'))
local env={StaticPopupDialogs={},shows=0,reloads=0,combat=false,loaded=false,db={enabled=true}}
setmetatable(env,{__index=_G})
env.InCombatLockdown=function() return env.combat end
env.IsAddOnLoaded=function(name) assert(name=='ElvUI_Enhanced');return env.loaded end
env.StaticPopup_Show=function(id) assert(env.StaticPopupDialogs[id]);env.shows=env.shows+1;return {} end
env.ReloadUI=function() env.reloads=env.reloads+1 end
env.DisableAddOn=function(name) assert(name=='IconBox');env.disabled=name end
env.Say=function() end
assert(load(code,'conflict','t',env))()
assert(not env.CheckConflict() and env.shows==0)
env.ElvUI={{private={enhanced={minimapButtonGrabber=true}}}};env.loaded=true
assert(env.Conflict())
env.combat=true;assert(env.CheckConflict() and env.shows==0)
env.combat=false;assert(env.CheckConflict() and env.shows==1)
assert(env.CheckConflict() and env.shows==1)
local popup=env.StaticPopupDialogs.ICONBOX_COLLECTOR_CONFLICT
popup.OnAccept();assert(not env.ElvUI[1].private.enhanced.minimapButtonGrabber and env.reloads==1)
assert(not env.Conflict())
env.ElvUI_MinimapButtonGrabber={};assert(env.Conflict(),'existing grabbed buttons require reload even after flag disabled')
popup.OnCancel(nil,nil,'override');assert(not env.disabled)
popup.OnCancel(nil,nil,'clicked');assert(env.db.enabled==false and env.reloads==2)
assert(not env.CheckConflict());env.db.enabled=true
env.disabled=nil;env.combat=true
popup.OnAccept();popup.OnCancel(nil,nil,'clicked');assert(not env.disabled and env.reloads==2)
env.combat=false;env.ElvUI=nil;popup.OnAccept();assert(env.reloads==2)
print('PASS: detection, pre-initialization flag, paused pending selection, deferred combat prompt, single prompt, both choices, reload and callback guards')
