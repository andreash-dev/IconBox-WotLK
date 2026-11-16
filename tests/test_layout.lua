local f=assert(io.open('IconBox/IconBox.lua') or io.open('IconBox.lua'));local source=f:read('*a');f:close()
local layout=assert(source:match('(local function Layout%(%).-)\nlocal conflictPrompted'))
local setup=[[
local db={enabled=true,columns=5,excluded={}}
local dirty=true
local function InCombatLockdown() return false end
local function Conflict() return false end
local function Collect() end
local function Release() end
local function Lock() end
local entries={}
local box={title={GetStringWidth=function() return 48 end},empty={GetStringWidth=function() return 100 end,Show=function() end,Hide=function() end}}
function box:SetWidth(w) self.width=w end
function box:SetHeight(h) self.height=h end
for i=1,12 do
 local button={IsShown=function() return true end,ClearAllPoints=function() end,SetScale=function() end,SetWidth=function() end,SetHeight=function() end}
 function button:SetPoint(_,_,_,x,y) self.x,self.y=x,y end
 entries[i]={label=string.format('%02d',i),name=tostring(i),button=button}
end
]]
local checks=[[
for _,columns in ipairs({5,10,4,3,2,1,6,2}) do
 db.columns=columns; Layout()
 local expected=math.max(columns*32+(columns-1)*8+28,96)
 assert(box.width==expected,'width must shrink and grow with columns')
 assert(box.height==math.ceil(12/columns)*40+48)
 local left=entries[1].button.x
 assert(math.abs(left-(box.width-(columns*32+(columns-1)*8))/2)<.001)
 for _,entry in ipairs(entries) do
  assert(entry.button.x>=0 and entry.button.x+32<=box.width)
  assert(-entry.button.y+32<=box.height)
 end
end
for _,entry in ipairs(entries) do db.excluded[entry.name]=true end
Layout();assert(box.width>=128,'empty message must fit')
print('PASS: widths shrink/grow for 1–10 columns, centered grid, icon bounds and empty panel')
]]
assert(load(setup..layout.."\n"..checks))()
