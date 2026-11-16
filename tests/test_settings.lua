-- Headless smoke test for the actual 3.3.5 settings construction and callbacks.
local root=_G
local frames, categories={},{}
local function object(name)
 local o={name=name,scripts={},shown=true,width=500,height=430,alpha=1,level=1,text='',value=0}
 function o:SetScript(k,v) self.scripts[k]=v end
 function o:HookScript(k,v) local old=self.scripts[k];self.scripts[k]=function(...) if old then old(...) end;v(...) end end
 function o:Show() local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
 function o:Hide() self.shown=false end
 function o:IsShown() return self.shown end
 function o:GetWidth() return self.width end
 function o:GetHeight() return self.height end
 function o:SetWidth(v) self.width=v end
 function o:SetHeight(v) self.height=v end
 function o:SetFrameStrata(value) self.strata=value end
 function o:GetFrameLevel() return self.level end
 function o:SetFrameLevel(v) self.level=v end
 function o:GetAlpha() return self.alpha end
 function o:SetAlpha(v) self.alpha=v end
 function o:SetBackdrop(v) self.backdrop=v end
 function o:GetBackdrop() return self.backdrop end
 function o:SetTemplate(v) self.template=v end
 function o:GetBackdropColor() return .1,.1,.1,.5 end
 function o:SetText(v) self.text=v end
 function o:GetText() return self.text end
 function o:GetStringWidth() return #self.text*6 end
 function o:SetChecked(v) self.checked=v end
 function o:GetCheckedTexture() self.tick=self.tick or object();return self.tick end
 function o:CreateFontString() return object() end
 function o:CreateTexture() return object() end
 function o:GetChildren() return end
 function o:GetCenter() return 100,100 end
 function o:SetValue(v) self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
 function o:SetPoint(...) self.point={...} end
 setmetatable(o,{__index=function(_,key) if key:match("^%u") then return function() end end end})
 return o
end
function CreateFrame(kind,name,parent,template)
 local o=object(name);table.insert(frames,o)
 if name then root[name]=o end
 if template=='OptionsSliderTemplate' then
  for _,suffix in ipairs({'Text','Low','High'}) do root[name..suffix]=object() end
 end
 return o
end
UIParent=object();Minimap=object();MinimapBackdrop=object()
UISpecialFrames={};StaticPopupDialogs={};SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
function InCombatLockdown() return false end
function GetRealmName() return "Test Realm" end
function UnitName() return "Test Character" end
function IsAddOnLoaded() return false end
function InterfaceOptions_AddCategory(panel) table.insert(categories,panel) end
function InterfaceOptionsFrame_OpenToCategory(panel) panel:Show() end
function StaticPopup_Hide() end
if arg[1]=='elvui' then
 local skin=setmetatable({},{__index=function() return function() end end})
 ElvUI={{db={},Media={Textures={Melli='elvui-fill'}},GetModule=function() return skin end}}
end
assert(loadfile('IconBox/IconBox.lua') or loadfile('IconBox.lua'))('IconBox',{})
frames[1].scripts.OnEvent(frames[1],'PLAYER_LOGIN')
assert(#categories==1 and categories[1].name=='IconBox')
assert(IconBoxLauncher.strata=='MEDIUM','launcher must stay above minimap pins')
assert(SLASH_ICONBOX1==nil and SlashCmdList.ICONBOX==nil)
local shift=false
function IsShiftKeyDown() return shift end
IconBoxLauncher.scripts.OnClick(IconBoxLauncher,'RightButton')
assert(not IconBoxSettings:IsShown(),'right-click alone must not open settings')
shift=true
IconBoxLauncher.scripts.OnClick(IconBoxLauncher,'RightButton')
shift=false
assert(IconBoxSettings:IsShown())
assert(IconBoxDB.transparent and IconBoxDB.direction=='DOWN')
IconBoxOption_columns:SetValue(2);assert(IconBoxDB.columns==2)
IconBoxOption_offsetX:SetValue(-35);IconBoxOption_offsetY:SetValue(17)
assert(IconBoxPanel.point[4]==-35 and IconBoxPanel.point[5]==9)
for _,frame in ipairs(frames) do
 if type(frame.text)=='table' and frame.text.text=='Left' then frame.scripts.OnClick(frame) end
end
assert(IconBoxDB.direction=='LEFT')
assert(IconBoxPanel.point[3]=='TOPLEFT' and IconBoxPanel.point[4]==-43 and IconBoxPanel.point[5]==17)
for _,frame in ipairs(frames) do
 if type(frame.text)=='table' and frame.text.text=='Transparent background' then frame.scripts.OnClick(frame) end
end
assert(not IconBoxDB.transparent)
if ElvUI then assert(IconBoxPanel.template=='Default') else assert(IconBoxPanel.backdrop.bgFile=='Interface\\Buttons\\WHITE8X8') end
for _,frame in ipairs(frames) do
 if type(frame.text)=='table' and frame.text.text=='Enable IconBox' then frame.scripts.OnClick(frame);assert(not IconBoxDB.enabled);frame.scripts.OnClick(frame);assert(IconBoxDB.enabled) end
end
print('PASS: Interface registration, no slash commands, Shift-right-click navigation, columns, offsets, left/down, transparency and enable/disable')

local previewed=false
for _,frame in ipairs(frames) do
 if frame.text=='Preview box' then frame.scripts.OnClick(frame);previewed=true end
end
assert(previewed and IconBoxSettings:IsShown() and IconBoxPanel:IsShown())
print('PASS: preview opens drawer without closing settings')

local sharing
for _,frame in ipairs(frames) do
 if type(frame.text)=='table' and frame.text.text=='Share settings across all characters' then sharing=frame end
end
assert(sharing)
local oldColumns=IconBoxDB.columns
sharing.scripts.OnClick(sharing)
local key='Test Realm - Test Character'
assert(IconBoxDB.useCharacter[key] and IconBoxDB.characters[key].columns==oldColumns)
IconBoxOption_columns:SetValue(7)
assert(IconBoxDB.characters[key].columns==7 and IconBoxDB.columns==oldColumns)
assert(IconBoxDB.characters[key].excluded~=IconBoxDB.excluded)
sharing.scripts.OnClick(sharing)
assert(not IconBoxDB.useCharacter[key] and IconBoxOption_columns.value==oldColumns)
sharing.scripts.OnClick(sharing)
assert(IconBoxOption_columns.value==7)
print('PASS: shared/personal switching, initial copy, isolated selection tables, preserved profiles and refreshed controls')
local firstNewFrame=#frames+1
function UnitName() return 'Other Character' end
assert(loadfile('IconBox/IconBox.lua') or loadfile('IconBox.lua'))('IconBox',{})
frames[firstNewFrame].scripts.OnEvent(frames[firstNewFrame],'PLAYER_LOGIN')
assert(not IconBoxDB.useCharacter['Test Realm - Other Character'])
IconBoxOption_columns:SetValue(3)
assert(IconBoxDB.columns==3 and IconBoxDB.characters[key].columns==7)
print('PASS: another character defaults to shared profile and cannot overwrite first character personal profile')

for _,field in ipairs({IconBoxOption_columnsValue,IconBoxOption_offsetXValue,IconBoxOption_offsetYValue}) do
 assert(field)
 if not ElvUI then assert(field.backdrop.bgFile=='Interface\\Buttons\\WHITE8X8') end
end
print('PASS: all three numeric fields use matching backgrounds')
