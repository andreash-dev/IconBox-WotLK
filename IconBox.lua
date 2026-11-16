-- Interface settings and runtime stay in one file for reliable 3.3.5 reloads.
local function CreateSettings(api)
    local db = api.db
    local panel = CreateFrame("Frame", "IconBoxSettings", UIParent)
    panel:Hide()
    panel.name = "IconBox"
    -- Updating controls must not write slider values back into the active profile.
    local syncing = false
    local checks, sliders = {}, {}
    api.Label(panel, "IconBox", 16, -16)
    local general = CreateFrame("Frame", nil, panel)
    general:SetPoint("TOPLEFT", 0, -64); general:SetPoint("BOTTOMRIGHT")
    local icons = CreateFrame("Frame", nil, panel)
    icons:SetPoint("TOPLEFT", 0, -64); icons:SetPoint("BOTTOMRIGHT"); icons:Hide()

    local function Button(parent, text, x, y, width, click)
        local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetSize(width, 24); button:SetPoint("TOPLEFT", x, y); button:SetText(text)
        button:SetScript("OnClick", click); api.SkinControl(button, "HandleButton")
        return button
    end
    local function Refresh()
        db = api.GetDB()
        syncing = true
        for _, item in ipairs(checks) do api.UpdateCheck(item.frame, item.read()) end
        for _, item in ipairs(sliders) do
            item.frame:SetValue(db[item.key]); item.edit:SetText(tostring(db[item.key]))
        end
        syncing = false
        api.ApplyTheme()
    end
    local profiles = CreateFrame("Frame", nil, panel)
    profiles:SetPoint("TOPLEFT", 0, -64); profiles:SetPoint("BOTTOMRIGHT"); profiles:Hide()
    local generalTab, iconsTab, profilesTab
    generalTab = Button(panel, "General", 16, -38, 100, function()
        icons:Hide(); profiles:Hide(); general:Show(); generalTab:Disable(); iconsTab:Enable(); profilesTab:Enable(); Refresh()
    end)
    iconsTab = Button(panel, "Icons", 120, -38, 100, function()
        general:Hide(); profiles:Hide(); icons:Show(); iconsTab:Disable(); generalTab:Enable(); profilesTab:Enable()
        api.Scan(); api.RefreshIcons()
    end)
    profilesTab = Button(panel, "Profiles", 224, -38, 100, function()
        general:Hide(); icons:Hide(); profiles:Show()
        profilesTab:Disable(); generalTab:Enable(); iconsTab:Enable(); Refresh()
    end)
    generalTab:Disable()

    local function Check(text, x, y, read, write, parent)
        local frame = api.MakeCheck(parent or general, text); frame:SetPoint("TOPLEFT", x, y)
        table.insert(checks, {frame = frame, read = read})
        frame:SetScript("OnClick", function()
            write(not read()); Refresh()
        end)
        return frame
    end
    api.Label(profiles, "Choose how IconBox settings are saved", 16, -10)
    Check("Share settings across all characters", 12, -38, 
        function() return api.IsShared() end, 
        function(value) api.SetShared(value) end, profiles)
    local profileHelp = api.Label(profiles, 
        "Checked: use the same layout and selected icons on all characters.\n\nUnchecked: use settings only for this character.\n\nYour first personal profile copies the shared settings.\nSwitching profiles preserves both sets of settings.", 20, -90)
    profileHelp:SetWidth(440); profileHelp:SetJustifyH("LEFT")
    Check("Enable IconBox", 12, -6, function() return db.enabled end, function(value) api.SetEnabled(value) end)
    Check("Transparent background", 12, -38, function() return db.transparent end, function(value)
        db.transparent = value; api.Apply()
    end)
    api.Label(general, "Open the box", 16, -82)
    Check("Down", 12, -98, function() return db.direction == "DOWN" end, function()
        db.direction = "DOWN"; api.Apply()
    end)
    Check("Left", 180, -98, function() return db.direction == "LEFT" end, function()
        db.direction = "LEFT"; api.Apply()
    end)

    local function Slider(key, title, y, minimum, maximum)
        api.Label(general, title, 16, y+22)
        local name = "IconBoxOption_"..key
        local frame = CreateFrame("Slider", name, general, "OptionsSliderTemplate")
        frame:SetPoint("TOPLEFT", 20, y); frame:SetSize(270, 16)
        frame:SetMinMaxValues(minimum, maximum); frame:SetValueStep(1)
        _G[name.."Text"]:SetText("")
        _G[name.."Low"]:SetText(tostring(minimum)); _G[name.."High"]:SetText(tostring(maximum))
        api.SkinControl(frame, "HandleSliderFrame")
        local edit = CreateFrame("EditBox", name.."Value", general)
        edit:SetFontObject(GameFontHighlight)
        edit:SetTextInsets(4, 4, 0, 0)
        edit:SetSize(56, 22); edit:SetPoint("LEFT", frame, "RIGHT", 24, 0)
        edit:SetAutoFocus(false); edit:SetMaxLetters(5); edit:SetJustifyH("CENTER")
        api.SkinControl(edit, "HandleEditBox")
        -- One complete field background avoids the template's mismatched texture pieces.
        if not edit.iconBoxSkinned then
            edit:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2}})
            edit:SetBackdropColor(.035, .035, .035, 1)
            edit:SetBackdropBorderColor(.45, .45, .45, 1)
        end
        local function Commit()
            local value = tonumber(edit:GetText())
            if value then
                value = math.max(minimum, math.min(maximum, math.floor(value+.5)))
                db[key] = value; api.Apply()
            end
            edit:SetText(tostring(db[key])); Refresh()
        end
        edit:SetScript("OnEnterPressed", function(self) Commit(); self:ClearFocus() end)
        edit:SetScript("OnEditFocusLost", Commit)
        edit:SetScript("OnEscapePressed", function(self) self:SetText(tostring(db[key])); self:ClearFocus() end)
        frame:SetScript("OnValueChanged", function(_, value)
            if syncing then return end
            db[key] = math.max(minimum, math.min(maximum, math.floor(value+.5)))
            edit:SetText(tostring(db[key])); api.Apply()
        end)
        table.insert(sliders, {key = key, frame = frame, edit = edit})
    end
    Slider("columns", "Columns", -164, 1, 10)
    Slider("offsetX", "Horizontal offset (negative = left, positive = right)", -220, -500, 500)
    Slider("offsetY", "Vertical offset (negative = down, positive = up)", -276, -500, 500)
    local preview = Button(general, "Preview box", 16, -320, 130, function()
        api.Preview()
    end)
    local reset = Button(general, "Reset layout", 156, -320, 130, function()
        db.columns = 5; db.direction = "DOWN"; db.offsetX = 0; db.offsetY = 0; db.transparent = true
        api.Apply(); Refresh()
    end)
    -- Keep bottom actions reachable on smaller Interface Options panels.
    preview:ClearAllPoints(); preview:SetPoint("BOTTOMLEFT", general, "BOTTOMLEFT", 16, 10)
    reset:ClearAllPoints(); reset:SetPoint("LEFT", preview, "RIGHT", 10, 0)

    api.Label(icons, "Checked icons are collected. Changes are saved immediately.", 16, -8)
    Button(icons, "Find new icons", 16, -30, 140, function() api.Scan(); api.RefreshIcons() end)
    local scroll = CreateFrame("ScrollFrame", "IconBoxSettingsScroll", icons, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -62); scroll:SetPoint("BOTTOMRIGHT", -34, 12)
    panel.content = CreateFrame("Frame", nil, scroll)
    panel.content:SetWidth(480); panel.content:SetHeight(1); scroll:SetScrollChild(panel.content)
    panel.empty = api.Label(icons, "No icons found. Enable IconBox and disable other collectors.", 20, -72)
    scroll:SetScript("OnSizeChanged", function(self, width)
        panel.content:SetWidth(math.max(100, width)); api.RefreshIcons()
    end)
    api.SkinControl(_G.IconBoxSettingsScrollScrollBar, "HandleScrollBar")
    panel:SetScript("OnShow", function() api.Scan(); api.RefreshIcons(); Refresh() end)
    panel.refresh = Refresh
    panel.okay = function() end
    panel.cancel = function() end
    InterfaceOptions_AddCategory(panel)
    return panel
end

local addon = CreateFrame("Frame")
local entries, byButton = {}, {}
local box, launcher, settings, db
local account, characterKey
local elapsed, dirty = 0, true
local Conflict, CheckConflict
local RefreshIconList
local methods = {"SetParent", "SetPoint", "ClearAllPoints", "SetScale", "SetSize", "SetWidth", "SetHeight"}
local ignore = {}
for name in string.gmatch("ElvConfigToggle BattlefieldMinimap ButtonCollectFrame GameTimeFrame MiniMapBattlefieldFrame MiniMapLFGFrame MiniMapMailFrame MiniMapPing MiniMapRecordingButton MiniMapTracking MiniMapTrackingButton MiniMapVoiceChatFrame MiniMapWorldMapButton Minimap MinimapBackdrop MinimapToggleButton MinimapZoneTextButton MinimapZoomIn MinimapZoomOut TimeManagerClockButton IconBoxLauncher", "%S+") do ignore[name] = true end
local patterns = {"GuildInstance", "GatherMatePin", "GatherNote", "GuildMap3Mini", "HandyNotesPin", "LibRockConfig", "NauticusMiniIcon", "WestPointer", "poiMinimap", "Spy_MapNoteList_mini", "Node", "Note", "Pin"}
local function Say(text) DEFAULT_CHAT_FRAME:AddMessage("|cff59c9ffIconBox:|r " .. text) end
-- Use native WoW controls by default and ElvUI skin helpers when available.
local themedPanels, themedLabels, themedControls = {}, {}, {}
local function ElvSkin()
    local E = type(ElvUI) == "table" and ElvUI[1]
    if not E or type(E.GetModule) ~= "function" or not E.db then return end
    local ok, skin = pcall(E.GetModule, E, "Skins", true)
    if ok and skin then return E, skin end
end
local function ApplyTheme()
    local E, skin = ElvSkin()
    if not skin then return end
    for _, frame in ipairs(themedPanels) do
        local template = db and db.transparent == false and "Default" or "Transparent"
        if frame.SetTemplate and frame.iconBoxTemplate ~= template then
            frame:SetTemplate(template)
            frame.iconBoxTemplate = template
            frame.iconBoxSkinned = true
        end
        if db and db.transparent == false then
            local r, g, b = frame:GetBackdropColor()
            frame:SetBackdropColor(r, g, b, 1)
        end
    end
    for _, label in ipairs(themedLabels) do
        if label.FontTemplate then label:FontTemplate() end
        label:SetTextColor(1, .82, 0)
    end
    for _, control in ipairs(themedControls) do
        if not control.frame.iconBoxSkinned and skin[control.handler] then
            skin[control.handler](skin, control.frame)
            control.frame.iconBoxSkinned = true
        end
    end
end
local function SkinControl(frame, handler)
    if frame then
        table.insert(themedControls, {frame = frame, handler = handler})
        ApplyTheme()
    end
end
local function Style(frame)
    frame:SetBackdrop({bgFile = db and db.transparent == false and "Interface\\Buttons\\WHITE8X8" or "Interface\\DialogFrame\\UI-DialogBox-Background", 
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, 
        tileSize = 32, edgeSize = 24, insets = {left = 6, right = 6, top = 6, bottom = 6}})
    if db and db.transparent == false then frame:SetBackdropColor(.06, .06, .06, 1) else frame:SetBackdropColor(1, 1, 1, 1) end
    frame:SetBackdropBorderColor(1, 1, 1, 1)
    table.insert(themedPanels, frame)
    frame:HookScript("OnShow", ApplyTheme)
    ApplyTheme()
end
local function Label(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y); label:SetText(text)
    table.insert(themedLabels, label)
    ApplyTheme()
    return label
end
-- Keep original button methods and anchors so excluded icons can be restored.
local function Lock(entry, enable)
    for _, method in ipairs(methods) do
        entry.button[method] = enable and function() end or entry.originalMethods[method]
    end
end
local function Capture(button)
    local name = button:GetName()
    if not name or ignore[name] or byButton[button] or button.isSkinned then return end
    if not string.find(name, "^LibDBIcon") then
        for _, pattern in ipairs(patterns) do if string.find(name, pattern, 1, true) then return end end
    end
    if button.IsProtected and button:IsProtected() then return end
    local entry = {button = button, name = name, parent = button:GetParent(), points = {}, originalMethods = {}, width = button:GetWidth(), height = button:GetHeight(), scale = button:GetScale(), dragStart = button:GetScript("OnDragStart"), dragStop = button:GetScript("OnDragStop")}
    for i = 1, button:GetNumPoints() do entry.points[i] = {button:GetPoint(i)} end
    for _, method in ipairs(methods) do entry.originalMethods[method] = rawget(button, method) end
    entry.label = string.gsub(name, "^LibDBIcon10_", "")
    -- Preserve the addon's handler and close only buttons currently in the drawer.
    local clickScript = button:GetScript("OnClick") and "OnClick" or "OnMouseUp"
    button:HookScript(clickScript, function(_, mouseButton)
        if (mouseButton == "LeftButton" or mouseButton == "RightButton")
            and entry.collected and box:IsShown() and not box.closing then
            box:Hide()
        end
    end)
    byButton[button] = entry; table.insert(entries, entry); dirty = true
end
local function Collect(entry)
    local button = entry.button
    if not entry.collected then
        button:SetParent(box)
        button:SetScript("OnDragStart", nil); button:SetScript("OnDragStop", nil)
        entry.collected = true
        Lock(entry, true)
    end
end
local function Release(entry)
    if not entry.collected then return end
    Lock(entry, false)
    local button = entry.button
    button:SetParent(entry.parent); button:ClearAllPoints()
    button:SetWidth(entry.width); button:SetHeight(entry.height); button:SetScale(entry.scale)
    for _, point in ipairs(entry.points) do button:SetPoint(unpack(point)) end
    button:SetScript("OnDragStart", entry.dragStart); button:SetScript("OnDragStop", entry.dragStop)
    entry.collected = false
end
local function PositionBox()
    box:ClearAllPoints()
    if db.direction == "LEFT" then
        box:SetPoint("TOPRIGHT", launcher, "TOPLEFT", -8 + db.offsetX, db.offsetY)
    else
        box:SetPoint("TOPRIGHT", launcher, "BOTTOMRIGHT", db.offsetX, -8 + db.offsetY)
    end
end
local function UpdateAppearance()
    if not ElvSkin() then
        local backdrop = box:GetBackdrop()
        backdrop.bgFile = db.transparent and "Interface\\DialogFrame\\UI-DialogBox-Background" or "Interface\\Buttons\\WHITE8X8"
        box:SetBackdrop(backdrop)
        if db.transparent then box:SetBackdropColor(1, 1, 1, 1) else box:SetBackdropColor(.06, .06, .06, 1) end
    end
    ApplyTheme()
    PositionBox()
end
-- Size the drawer from shown icons, leaving room only for its header and padding.
local function Layout()
    if not db.enabled or InCombatLockdown() or Conflict() then dirty = true; return end
    table.sort(entries, function(a, b) return string.lower(a.label)<string.lower(b.label) end)
    local visible = {}
    for _, entry in ipairs(entries) do
        if db.excluded[entry.name] then Release(entry) else
            Collect(entry)
            -- IsShown remains true when the closed container hides its children.
            if entry.button:IsShown() then table.insert(visible, entry) end
        end
    end
    local columns = math.min(db.columns, math.max(1, #visible))
    local rows = math.max(1, math.ceil(#visible/columns))
    local gridWidth = columns * 32 + (columns - 1) * 8
    local headerWidth = box.title:GetStringWidth() + 48
    local width = math.max(gridWidth + 28, headerWidth)
    if #visible == 0 then width = math.max(width, box.empty:GetStringWidth() + 28) end
    local left = (width - gridWidth) / 2
    box:SetWidth(width)
    box:SetHeight(rows*40+48)
    for i, entry in ipairs(visible) do
        Lock(entry, false)
        local button = entry.button
        button:ClearAllPoints(); button:SetScale(1); button:SetWidth(32); button:SetHeight(32)
        button:SetPoint("TOPLEFT", box, "TOPLEFT", left+((i-1)%columns)*40, -38-math.floor((i-1)/columns)*40)
        Lock(entry, true)
    end
    if #visible == 0 then box.empty:Show() else box.empty:Hide() end
    dirty = false
end
-- Never let two collectors move the same buttons; switch via a clean UI reload.
local conflictPrompted = false
local function GrabberSettings()
    local E = type(ElvUI) == "table" and ElvUI[1]
    return E and E.private and E.private.enhanced
end
Conflict = function()
    local private = GrabberSettings()
    return ElvUI_MinimapButtonGrabber ~= nil
        or (IsAddOnLoaded("ElvUI_Enhanced") and private and private.minimapButtonGrabber)
end
StaticPopupDialogs["ICONBOX_COLLECTOR_CONFLICT"] = {
    text = "IconBox and ElvUI Enhanced Button Grabber cannot collect icons together.\n\nChoose which one to use. The other collector will be turned off and your UI will reload.", 
    button1 = "Use IconBox", 
    button2 = "Use ElvUI Grabber", 
    OnAccept = function()
        if InCombatLockdown() then
            conflictPrompted = false
            Say("Choose your icon collector outside combat.")
            return
        end
        local private = GrabberSettings()
        if not private then
            conflictPrompted = false
            Say("Unable to access ElvUI settings. Disable its Button Grabber manually.")
            return
        end
        private.minimapButtonGrabber = false
        ReloadUI()
    end, 
    OnCancel = function(_, _, reason)
        if reason and reason ~= "clicked" then conflictPrompted = false; return end
        if InCombatLockdown() then
            conflictPrompted = false
            Say("Choose your icon collector outside combat.")
            return
        end
        db.enabled = false
        ReloadUI()
    end, 
    timeout = 0, 
    whileDead = 1, 
    hideOnEscape = false, 
    preferredIndex = 3, 
}
CheckConflict = function()
    if not db.enabled or not Conflict() then return false end
    -- Collection stays paused even if the prompt has not yet been answered.
    if not conflictPrompted and not InCombatLockdown() then
        conflictPrompted = StaticPopup_Show("ICONBOX_COLLECTOR_CONFLICT") ~= nil
    end
    return true
end
local function Scan()
    if not db.enabled or InCombatLockdown() or CheckConflict() then return end
    for _, parent in ipairs({Minimap, MinimapBackdrop}) do
        if parent then
            local children = {parent:GetChildren()}
            for _, button in ipairs(children) do if button:IsObjectType("Button") then Capture(button) end end
        end
    end
    for _, name in ipairs({"AtlasButton", "FishingBuddyMinimapButton", "HealBot_MMButton"}) do
        if _G[name] then Capture(_G[name]) end
    end
    Layout()
    if settings and settings:IsShown() and RefreshIconList then RefreshIconList() end
end
local minimapShapes = {
  ROUND = {true, true, true, true}, 
  SQUARE = {false, false, false, false}, 
  ["CORNER-TOPLEFT"] = {true, false, false, false}, 
  ["CORNER-TOPRIGHT"] = {false, false, true, false}, 
  ["CORNER-BOTTOMLEFT"] = {false, true, false, false}, 
  ["CORNER-BOTTOMRIGHT"] = {false, false, false, true}, 
  ["SIDE-LEFT"] = {true, true, false, false}, 
  ["SIDE-RIGHT"] = {false, false, true, true}, 
  ["SIDE-TOP"] = {true, false, true, false}, 
  ["SIDE-BOTTOM"] = {false, true, false, true}, 
  ["TRICORNER-TOPLEFT"] = {true, true, true, false}, 
  ["TRICORNER-TOPRIGHT"] = {true, false, true, true}, 
  ["TRICORNER-BOTTOMLEFT"] = {true, true, false, true}, 
  ["TRICORNER-BOTTOMRIGHT"] = {false, true, true, true}, 
}

local function PositionLauncher()
  local angle = db.angle
  local rad = math.rad(angle)
  local x, y = math.cos(rad), math.sin(rad)
  local width, height = Minimap:GetWidth(), Minimap:GetHeight()
  -- Match the minimap shape, with a small inset along square edges.
  local halfWidth = width and width > 0 and width / 2 or 70
  local halfHeight = height and height > 0 and height / 2 or 70
  local rx, ry = halfWidth + 10, halfHeight + 10
  local quadrant = 1
  if x < 0 then quadrant = quadrant + 1 end
  if y > 0 then quadrant = quadrant + 2 end
  local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
  local rounded = minimapShapes[shape] or minimapShapes.ROUND
  if rounded[quadrant] then
    x, y = x * rx, y * ry
  else
    -- Inset the button center from the rectangular edge.
    rx, ry = math.max(1, halfWidth - 7), math.max(1, halfHeight - 7)
    local distance = 1 / math.max(math.abs(x) / rx, math.abs(y) / ry)
    x, y = x * distance, y * distance
  end
  launcher:ClearAllPoints()
  launcher:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- One transition handles both directions and can reverse mid-animation.
local function FadeBox(open)
    box.closing = not open
    if open then
        if not box:IsShown() then box:SetAlpha(0); box:Show() end
    elseif not box:IsShown() then
        return
    end
    local start, target, time = box:GetAlpha(), open and 1 or 0, 0
    box:SetScript("OnUpdate", function(self, delta)
        time = math.min(.14, time + delta)
        self:SetAlpha(start + (target - start) * (time / .14))
        if time >= .14 then
            self:SetScript("OnUpdate", nil)
            if target == 0 then self:HideImmediately(); self:SetAlpha(1) end
            self.closing = nil
        end
    end)
end
local function ToggleBox()
    if not db.enabled then Say("Enable IconBox in Interface > AddOns > IconBox."); return end
    if box:IsShown() and not box.closing then box:Hide(); return end
    Scan(); FadeBox(true)
end
-- Render selection from SavedVariables, independently of native checked textures.
local function UpdateCheck(row, included)
    row:SetChecked(included)
    local nativeTick = row:GetCheckedTexture()
    if nativeTick then nativeTick:SetAlpha(0) end
    row.selection:SetFrameLevel(row:GetFrameLevel() + 10)
    local E, skin = ElvSkin()
    local tick = row.selection.tick
    if skin then
        tick:SetTexture(E.Media and E.Media.Textures and E.Media.Textures.Melli
            or "Interface\\Buttons\\WHITE8X8")
        tick:SetSize(16, 16)
        tick:SetVertexColor(1, .82, 0, .8)
    else
        tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        tick:SetSize(24, 24)
        tick:SetVertexColor(1, 1, 1, 1)
    end
    if included then row.selection:Show() else row.selection:Hide() end
end
local function MakeCheck(parent, text)
    local row = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    row.text = Label(row, text, 32, -8)
    SkinControl(row, "HandleCheckBox")
    row.selection = CreateFrame("Frame", nil, row)
    row.selection:SetAllPoints(row)
    row.selection:EnableMouse(false)
    local tick = row.selection:CreateTexture(nil, "OVERLAY")
    row.selection.tick = tick
    tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    tick:SetSize(24, 24)
    tick:SetPoint("CENTER", row.selection, "CENTER", 0, 0)
    return row
end
RefreshIconList = function()
    settings.rows = settings.rows or {}
    for _, row in ipairs(settings.rows) do row:Hide() end
    for i, entry in ipairs(entries) do
        local row = settings.rows[i]
        if not row then
            row = MakeCheck(settings.content, "")
            settings.rows[i] = row
        end
        row:SetPoint("TOPLEFT", 4, -(i-1)*30)
        row.text:SetText(entry.label); row.text:SetWidth(math.max(120, settings.content:GetWidth()-42)); row.text:SetJustifyH("LEFT"); UpdateCheck(row, not db.excluded[entry.name]); row:Show()
        local selected = entry
        row:SetScript("OnClick", function(self)
            if InCombatLockdown() then
                UpdateCheck(self, not db.excluded[selected.name])
                Say("Change collection settings outside combat.")
                return
            end
            -- Toggle the saved choice; older clients differ in GetChecked return values.
            db.excluded[selected.name] = not db.excluded[selected.name] or nil
            UpdateCheck(self, not db.excluded[selected.name])
            Layout()
        end)
    end
    settings.content:SetHeight(math.max(1, #entries*30))
    if #entries == 0 then settings.empty:Show() else settings.empty:Hide() end
end
local function ShowSettings()
    box:Hide()
    InterfaceOptionsFrame_OpenToCategory(settings)
    -- The legacy options tree can select the wrong category on its first call.
    InterfaceOptionsFrame_OpenToCategory(settings)
end
local function SetEnabled(enabled)
    if InCombatLockdown() then Say("Change collection settings outside combat."); return end
    db.enabled = enabled
    conflictPrompted = false
    if enabled then launcher:Show(); Scan() else
        StaticPopup_Hide("ICONBOX_COLLECTOR_CONFLICT")
        box:Hide()
        for _, entry in ipairs(entries) do Release(entry) end
        launcher:Hide()
    end
end
-- The original saved table is the shared profile; personal profiles are keyed by realm/name.
local function InitializeProfiles()
    IconBoxDB = IconBoxDB or {}
    account = IconBoxDB
    account.characters = account.characters or {}
    account.useCharacter = account.useCharacter or {}
    characterKey = GetRealmName() .. " - " .. UnitName("player")
    db = account.useCharacter[characterKey] and account.characters[characterKey] or account
end
local function SetShared(shared)
    if InCombatLockdown() then Say("Switch profiles outside combat."); return end
    -- Restore original frames before applying the target profile's selection.
    for _, entry in ipairs(entries) do Release(entry) end
    if not shared and not account.characters[characterKey] then
        local profile = {}
        for _, key in ipairs({"enabled", "angle", "columns", "transparent", "direction", "offsetX", "offsetY"}) do
            profile[key] = account[key]
        end
        profile.excluded = {}
        for name, excluded in pairs(account.excluded) do profile.excluded[name] = excluded end
        account.characters[characterKey] = profile
    end
    account.useCharacter[characterKey] = not shared or nil
    db = shared and account or account.characters[characterKey]
    box:Hide()
    PositionLauncher()
    UpdateAppearance()
    SetEnabled(db.enabled)
    RefreshIconList()
end
-- Build the UI once, then rescan outside combat for addons that create buttons later.
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if db then Scan() end
        return
    end
    InitializeProfiles()
    if db.enabled == nil then db.enabled = true end
    db.excluded = db.excluded or {}
    db.angle = db.angle or 225
    db.columns = db.columns or 5
    if db.transparent == nil then db.transparent = true end
    db.direction = db.direction == "LEFT" and "LEFT" or "DOWN"
    db.offsetX = math.max(-500, math.min(500, tonumber(db.offsetX) or 0))
    db.offsetY = math.max(-500, math.min(500, tonumber(db.offsetY) or 0))
    db.columns = math.max(1, math.min(10, tonumber(db.columns) or 5))
    box = CreateFrame("Frame", "IconBoxPanel", UIParent); Style(box)
    box:SetFrameStrata("DIALOG"); box:SetClampedToScreen(true); box:EnableMouse(true)
    box.title = Label(box, "IconBox", 12, -12)
    box.empty = Label(box, "No collected icons", 14, -46)
    box:Hide()
    -- Route the close button and Escape through the same fade as the launcher.
    box.HideImmediately = box.Hide
    box.Hide = function() FadeBox(false) end
    table.insert(UISpecialFrames, "IconBoxPanel")
    local close = CreateFrame("Button", nil, box, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -3, -3)
    SkinControl(close, "HandleCloseButton")
    launcher = CreateFrame("Button", "IconBoxLauncher", Minimap); launcher:SetSize(31, 31); launcher:SetFrameLevel(8)
    launcher:SetMovable(true); launcher:RegisterForDrag("LeftButton")
    launcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local icon = launcher:CreateTexture(nil, "ARTWORK"); icon:SetTexture("Interface\\AddOns\\IconBox\\Textures\\IconBox")
    icon:SetSize(18, 18); icon:SetPoint("CENTER", launcher, "CENTER", 1, 0)
    icon:SetTexCoord(0, 1, 0, 1)
    local border = launcher:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54); border:SetPoint("TOPLEFT", launcher, "TOPLEFT")
    launcher:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    launcher:SetScript("OnClick", function(_, button)
        if button == "RightButton" and IsShiftKeyDown() then ShowSettings()
        elseif button == "LeftButton" then ToggleBox() end
    end)
    launcher:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition(); local cx, cy = Minimap:GetCenter(); local scale = Minimap:GetEffectiveScale()
            db.angle = math.deg(math.atan2(y/scale-cy, x/scale-cx)); PositionLauncher()
        end)
    end)
    launcher:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    launcher:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("IconBox", .35, .8, 1)
        GameTooltip:AddLine("Left-click: open box", 1, 1, 1); GameTooltip:AddLine("Shift-right-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: move around minimap", .7, .7, .7); GameTooltip:Show()
    end)
    launcher:SetScript("OnLeave", function() GameTooltip:Hide() end)
    PositionLauncher(); PositionBox()
    settings = CreateSettings({
        db = db, GetDB = function() return db end, 
        IsShared = function() return not account.useCharacter[characterKey] end, 
        SetShared = SetShared, Label = Label, MakeCheck = MakeCheck, UpdateCheck = UpdateCheck, 
        SkinControl = SkinControl, ApplyTheme = ApplyTheme, Scan = Scan, 
        RefreshIcons = function() RefreshIconList() end, 
        SetEnabled = SetEnabled, 
        Apply = function() UpdateAppearance(); Layout() end, 
        Preview = function() UpdateAppearance(); if db.enabled then Scan(); FadeBox(true) end end, 
    })
    UpdateAppearance()
    if not db.enabled then launcher:Hide() end
    self:SetScript("OnUpdate", function(_, delta)
        if not db.enabled then return end
        elapsed = elapsed+delta
        if elapsed >= 3 then
            elapsed = 0
            PositionLauncher()
            Scan()
        elseif dirty and not InCombatLockdown() and not Conflict() then
            Layout()
        end
    end)
    Scan()
end)
