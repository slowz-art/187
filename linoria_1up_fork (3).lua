local cloneref = (cloneref or clonereference or function(instance: any) return instance end)
local InputService: UserInputService = cloneref(game:GetService('UserInputService'));
local TextService: TextService = cloneref(game:GetService('TextService'));
local CoreGui: CoreGui = cloneref(game:GetService('CoreGui'));
local Teams: Teams = cloneref(game:GetService('Teams'));
local Players: Players = cloneref(game:GetService('Players'));
local RunService: RunService = cloneref(game:GetService('RunService'));
local TweenService: TweenService = cloneref(game:GetService('TweenService'));
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local DrawingLib = typeof(Drawing) == "table" and Drawing or { drawing_replaced = true };
local ProtectGui = protectgui or (function() end);
local GetHUI = gethui or (function() return CoreGui end);

local IsBadDrawingLib = false;

local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    if not pcall(function()
        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end) then
        Instance.Parent = LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(ProtectGui, UI)
    SafeParentUI(UI, GetHUI)
end

@@ -7324,607 +7325,691 @@
                Library.AttachOptionSearch(Window);
            end;
        end);
    end);

    return Window;
end;

local function OnPlayerChange()
    local PlayerList, ExcludedPlayerList = GetPlayers(false, true), GetPlayers(true, true);
    local StringPlayerList, StringExcludedPlayerList = GetPlayers(false, false), GetPlayers(true, false);

    for _, Value in next, Options do
        if Value.SetValues and Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(
                if Value.ReturnInstanceInstead then
                    (if Value.ExcludeLocalPlayer then ExcludedPlayerList else PlayerList)
                else
                    (if Value.ExcludeLocalPlayer then StringExcludedPlayerList else StringPlayerList)
            );
        end;
    end;
end;

local function OnTeamChange()
    local TeamList = GetTeams(false);
    local StringTeamList = GetTeams(true);

    for _, Value in next, Options do
        if Value.SetValues and Value.Type == 'Dropdown' and Value.SpecialType == 'Team' then
            Value:SetValues(if Value.ReturnInstanceInstead then TeamList else StringTeamList);
        end;
    end;
end;

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange));
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange));

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange));
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange));

if getgenv().skip_getgenv_linoria ~= true then getgenv().Library = Library end
-- =====================================================
-- OPTION SEARCH + MULTI CONFIG PROFILES
-- OPTION SEARCH + MULTI CONFIG (Linoria-style SaveManager)
-- =====================================================

Library.SearchIndex = Library.SearchIndex or {};
Library.Windows = Library.Windows or {};

local HttpService = game:GetService("HttpService");
local TweenService = game:GetService("TweenService");

local function safeIsfile(p)
    local ok, r = pcall(function() return isfile(p) end);
    return ok and r;
end;
local function safeWrite(p, data)
    pcall(function() writefile(p, data) end);
end;
local function safeRead(p)
    local ok, r = pcall(function() return readfile(p) end);
    return ok and r or nil;
end;
local function safeList(folder)
    local out = {};
    pcall(function()
        for _, file in ipairs(listfiles(folder)) do
            out[#out + 1] = file;
        end;
    end);
    return out;
end;
local function ensureFolder(folder)
    pcall(function()
        if not isfolder(folder) then makefolder(folder) end;
    end);
end;
local function sm_isfolder(p)
    local ok, r = pcall(function() return isfolder(p) end)
    return ok and r
end
local function sm_isfile(p)
    local ok, r = pcall(function() return isfile(p) end)
    return ok and r
end
local function sm_makefolder(p)
    pcall(function() makefolder(p) end)
end
local function sm_writefile(p, d)
    local ok, err = pcall(function() writefile(p, d) end)
    return ok, err
end
local function sm_readfile(p)
    local ok, r = pcall(function() return readfile(p) end)
    return ok and r or nil
end
local function sm_listfiles(p)
    local ok, r = pcall(function() return listfiles(p) end)
    return (ok and type(r) == "table") and r or {}
end
local function sm_delfile(p)
    local ok = pcall(function() delfile(p) end)
    return ok
end

-- ----- Config serialize -----
function Library:GetConfig()
    local data = {
        Toggles = {};
        Options = {};
        Version = 1;
    };
-- ===================== LINORIA-STYLE SAVEMANAGER =====================
local SaveManager = {} do
    SaveManager.Folder = "LinoriaLibSettings"
    SaveManager.SubFolder = ""
    SaveManager.Ignore = {}
    SaveManager.Library = nil
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = "Toggle", idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Toggles[idx]
                if object and object.SetValue and object.Value ~= data.value then
                    object:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = "Slider", idx = idx, value = tostring(object.Value) }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object and object.SetValue then
                    object:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = "Dropdown", idx = idx, value = object.Value, multi = object.Multi }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object and object.SetValue then
                    object:SetValue(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                local v = object.Value
                local hex = (typeof(v) == "Color3" and v.ToHex) and v:ToHex() or "ffffff"
                return { type = "ColorPicker", idx = idx, value = hex, transparency = object.Transparency }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object then
                    local col = Color3.fromHex(data.value)
                    if object.SetValueRGB then
                        object:SetValueRGB(col, data.transparency)
                    elseif object.SetValue then
                        object:SetValue(col)
                    end
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type = "KeyPicker", idx = idx, mode = object.Mode, key = object.Value, modifiers = object.Modifiers }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object and object.SetValue then
                    object:SetValue({ data.key, data.mode, data.modifiers })
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = "Input", idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object and object.SetValue and type(data.text) == "string" then
                    object:SetValue(data.text)
                end
            end,
        },
    }

    for idx, toggle in pairs(Toggles) do
        if type(idx) == "string" and toggle and toggle.Value ~= nil then
            data.Toggles[idx] = toggle.Value and true or false;
        end;
    end;
    function SaveManager:SetLibrary(library)
        self.Library = library
        if library then
            library.SaveManager = self
            library.Toggles = library.Toggles or Toggles
            library.Options = library.Options or Options
        end
    end

    for idx, option in pairs(Options) do
        if type(idx) == "string" and option then
            local t = option.Type;
            if t == "ColorPicker" then
                local c = option.Value or option.Color;
                if typeof(c) == "Color3" then
                    data.Options[idx] = {
                        Type = "ColorPicker";
                        R = c.R; G = c.G; B = c.B;
                        Transparency = option.Transparency;
                    };
                end;
            elseif t == "KeyPicker" then
                data.Options[idx] = {
                    Type = "KeyPicker";
                    Key = option.Value or option.Key;
                    Mode = option.Mode;
                };
            elseif option.Value ~= nil then
                data.Options[idx] = {
                    Type = t or "Value";
                    Value = option.Value;
                };
            end;
        end;
    end;
    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
            "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
            "VideoLink",
        })
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data);
    end);
    return ok and encoded or "{}";
end;
    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

function Library:LoadConfig(json)
    if type(json) ~= "string" or json == "" then return end;
    local ok, data = pcall(function()
        return HttpService:JSONDecode(json);
    end);
    if not ok or type(data) ~= "table" then return end;
    function SaveManager:CheckSubFolder(createFolder)
        if typeof(self.SubFolder) ~= "string" or self.SubFolder == "" then return false end
        if createFolder == true then
            local path = self.Folder .. "/settings/" .. self.SubFolder
            if not sm_isfolder(path) then sm_makefolder(path) end
        end
        return true
    end

    if type(data.Toggles) == "table" then
        for idx, val in pairs(data.Toggles) do
            local toggle = Toggles[idx];
            if toggle and toggle.SetValue then
                pcall(function() toggle:SetValue(val and true or false) end);
            end;
        end;
    end;
    function SaveManager:BuildFolderTree()
        local paths = {}
        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end
        paths[#paths + 1] = self.Folder .. "/themes"
        paths[#paths + 1] = self.Folder .. "/settings"
        if self:CheckSubFolder(false) then
            local sub = self.Folder .. "/settings/" .. self.SubFolder
            local sp = sub:split("/")
            for idx = 1, #sp do
                paths[#paths + 1] = table.concat(sp, "/", 1, idx)
            end
        end
        for i = 1, #paths do
            if not sm_isfolder(paths[i]) then sm_makefolder(paths[i]) end
        end
    end

    if type(data.Options) == "table" then
        for idx, entry in pairs(data.Options) do
            local option = Options[idx];
            if option and type(entry) == "table" then
                pcall(function()
                    if entry.Type == "ColorPicker" and option.SetValueRGB then
                        option:SetValueRGB(Color3.new(entry.R or 1, entry.G or 1, entry.B or 1), entry.Transparency);
                    elseif entry.Type == "ColorPicker" and option.SetValue then
                        option:SetValue(Color3.new(entry.R or 1, entry.G or 1, entry.B or 1));
                    elseif entry.Type == "KeyPicker" and option.SetValue then
                        option:SetValue({ entry.Key, entry.Mode });
                    elseif entry.Value ~= nil and option.SetValue then
                        option:SetValue(entry.Value);
                    end;
                end);
            end;
        end;
    end;
end;
    function SaveManager:CheckFolderTree()
        if sm_isfolder(self.Folder) then return end
        self:BuildFolderTree()
        task.wait(0.1)
    end

-- ----- Multi-profile SaveManager -----
local SaveManager = {};
SaveManager.Library = Library;
SaveManager.Folder = "ProjectX/configs";
SaveManager.Ignore = {};
SaveManager.CurrentProfile = "default";
SaveManager.__index = SaveManager;

function SaveManager:SetLibrary(Lib)
    self.Library = Lib or Library;
    Library.SaveManager = self;
end;
    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

function SaveManager:SetFolder(Folder)
    self.Folder = Folder or "ProjectX/configs";
    ensureFolder(self.Folder);
end;
    function SaveManager:SetSubFolder(folder)
        self.SubFolder = folder
        self:BuildFolderTree()
    end

function SaveManager:IgnoreThemeSettings()
    self.Ignore.Theme = true;
end;
    function SaveManager:Save(name)
        if not name then return false, "no config file is selected" end
        self:CheckFolderTree()

function SaveManager:SetIgnoreIndexes(Indexes)
    for _, idx in ipairs(Indexes or {}) do
        self.Ignore[idx] = true;
    end;
end;
        local fullPath = self.Folder .. "/settings/" .. name .. ".json"
        if self:CheckSubFolder(true) then
            fullPath = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. ".json"
        end

function SaveManager:GetPath(Name)
    return self.Folder .. "/" .. tostring(Name or self.CurrentProfile or "default") .. ".json";
end;
        local data = { objects = {} }
        local Lib = self.Library or Library

function SaveManager:Save(Name)
    Name = Name or self.CurrentProfile or "default";
    self.CurrentProfile = Name;
    ensureFolder(self.Folder);
    safeWrite(self:GetPath(Name), Library:GetConfig());
    return true;
end;
        for idx, toggle in next, (Lib.Toggles or Toggles) do
            if toggle.Type and self.Parser[toggle.Type] and not self.Ignore[idx] then
                table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
            end
        end
        for idx, option in next, (Lib.Options or Options) do
            if option.Type and self.Parser[option.Type] and not self.Ignore[idx] then
                table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
            end
        end

function SaveManager:Load(Name)
    Name = Name or self.CurrentProfile or "default";
    local raw = safeRead(self:GetPath(Name));
    if not raw then return false end;
    self.CurrentProfile = Name;
    Library:LoadConfig(raw);
    return true;
end;
        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then return false, "failed to encode data" end

function SaveManager:Delete(Name)
    Name = Name or self.CurrentProfile;
    pcall(function()
        local p = self:GetPath(Name);
        if isfile(p) then delfile(p) end;
    end);
end;
        local ok = sm_writefile(fullPath, encoded)
        if not ok then return false, "failed to write file" end
        return true
    end

function SaveManager:RefreshConfigList()
    ensureFolder(self.Folder);
    local list = {};
    for _, file in ipairs(safeList(self.Folder)) do
        local name = file:match("([^/\\]+)%.json$");
        if name and name ~= "autoload" then
            list[#list + 1] = name;
        end;
    end;
    table.sort(list);
    return list;
end;
    function SaveManager:Load(name)
        if not name then return false, "no config file is selected" end
        self:CheckFolderTree()

function SaveManager:SaveAutoloadConfig(Name)
    ensureFolder(self.Folder);
    safeWrite(self.Folder .. "/autoload.json", tostring(Name or self.CurrentProfile or "default"));
end;
        local file = self.Folder .. "/settings/" .. name .. ".json"
        if self:CheckSubFolder(true) then
            file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. ".json"
        end
        if not sm_isfile(file) then return false, "invalid file" end

function SaveManager:LoadAutoloadConfig()
    local name = safeRead(self.Folder .. "/autoload.json");
    if name and name ~= "" then
        self:Load(name);
    end;
end;
        local raw = sm_readfile(file)
        if not raw then return false, "read error" end
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
        if not success then return false, "decode error" end

function SaveManager:BuildConfigSection(Tab)
    if not Tab then return end;
    local box = (Tab.AddLeftGroupbox and Tab:AddLeftGroupbox("Configs"))
        or (Tab.AddRightGroupbox and Tab:AddRightGroupbox("Configs"));
    if not box then return end;
        for _, option in ipairs(decoded.objects or {}) do
            if option.type and self.Parser[option.type] and not self.Ignore[option.idx] then
                task.spawn(self.Parser[option.type].Load, option.idx, option)
            end
        end
        return true
    end

    local selected = self.CurrentProfile;
    local nameBox = "";
    function SaveManager:Delete(name)
        if not name then return false, "no config file is selected" end
        local file = self.Folder .. "/settings/" .. name .. ".json"
        if self:CheckSubFolder(true) then
            file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. ".json"
        end
        if not sm_isfile(file) then return false, "invalid file" end
        if not sm_delfile(file) then return false, "delete file error" end
        return true
    end

    local listDrop;
    listDrop = box:AddDropdown("SM_ConfigList", {
        Text = "Profile";
        Values = self:RefreshConfigList();
        Default = 1;
        Callback = function(v)
            selected = v;
        end;
    });
    function SaveManager:RefreshConfigList()
        local ok, data = pcall(function()
            self:CheckFolderTree()
            local list
            if self:CheckSubFolder(true) then
                list = sm_listfiles(self.Folder .. "/settings/" .. self.SubFolder)
            else
                list = sm_listfiles(self.Folder .. "/settings")
            end
            local out = {}
            for i = 1, #list do
                local file = list[i]
                if file:sub(-5) == ".json" then
                    local name = file:match("([^/\\]+)%.json$")
                    if name and name ~= "autoload" then
                        out[#out + 1] = name
                    end
                end
            end
            table.sort(out)
            return out
        end)
        if not ok then return {} end
        return data
    end

    if box.AddInput then
        box:AddInput("SM_ConfigName", {
            Default = "";
            Placeholder = "New profile name";
            Finished = true;
            Callback = function(v) nameBox = v end;
        });
    elseif box.AddTextbox then
        box:AddTextbox("SM_ConfigName", {
            Text = "New profile name";
            Default = "";
            Placeholder = "New profile name";
            Callback = function(v) nameBox = v end;
        });
    end;
    function SaveManager:GetAutoloadConfig()
        self:CheckFolderTree()
        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if self:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        if sm_isfile(autoLoadPath) then
            local name = tostring(sm_readfile(autoLoadPath) or "")
            return (name == "" and "none") or name
        end
        return "none"
    end

    local function refreshDrop()
        if listDrop and listDrop.SetValues then
            listDrop:SetValues(self:RefreshConfigList());
        end;
    end;
    function SaveManager:LoadAutoloadConfig()
        local name = self:GetAutoloadConfig()
        if name ~= "none" then
            local success, err = self:Load(name)
            if not success and self.Library then
                self.Library:Notify("Failed to load autoload config: " .. tostring(err))
            end
        end
    end

    box:AddButton({
        Text = "Create / Save As";
        Func = function()
            local n = (nameBox and nameBox ~= "" and nameBox) or selected;
            if n and n ~= "" then
                self:Save(n);
                refreshDrop();
                Library:Notify("Saved profile: " .. tostring(n), 2);
            end;
        end;
    });
    function SaveManager:SaveAutoloadConfig(name)
        self:CheckFolderTree()
        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if self:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        sm_writefile(autoLoadPath, tostring(name or ""))
        return true
    end

    box:AddButton({
        Text = "Load Profile";
        Func = function()
            if selected then
                self:Load(selected);
                Library:Notify("Loaded: " .. tostring(selected), 2);
            end;
        end;
    });
    function SaveManager:DeleteAutoLoadConfig()
        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if self:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        if sm_isfile(autoLoadPath) then sm_delfile(autoLoadPath) end
        return true
    end

    box:AddButton({
        Text = "Overwrite Selected";
        Func = function()
            if selected then
                self:Save(selected);
                Library:Notify("Overwrote: " .. tostring(selected), 2);
            end;
        end;
    });
    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "SaveManager:BuildConfigSection -> Must set SaveManager.Library")
        local section = tab:AddRightGroupbox("Configuration")

    box:AddButton({
        Text = "Delete Profile";
        Func = function()
            if selected then
                self:Delete(selected);
                refreshDrop();
                Library:Notify("Deleted: " .. tostring(selected), 2);
            end;
        end;
    });
        section:AddInput("SaveManager_ConfigName", { Text = "Config name" })

    box:AddButton({
        Text = "Set Autoload";
        Func = function()
            if selected then
                self:SaveAutoloadConfig(selected);
                Library:Notify("Autoload = " .. tostring(selected), 2);
            end;
        end;
    });
        section:AddButton("Create config", function()
            local name = self.Library.Options.SaveManager_ConfigName.Value
            if not name or name:gsub(" ", "") == "" then
                self.Library:Notify("Invalid config name (empty)", 2)
                return
            end
            local success, err = self:Save(name)
            if not success then
                self.Library:Notify("Failed to create config: " .. tostring(err))
                return
            end
            self.Library:Notify(string.format('Created config "%s"', name))
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

    box:AddButton({
        Text = "Refresh List";
        Func = function()
            refreshDrop();
        end;
    });
end;
        section:AddDivider()

Library.SaveManager = SaveManager;
pcall(function()
    if getgenv then
        getgenv().SaveManager = SaveManager;
    end;
end);
        section:AddDropdown("SaveManager_ConfigList", {
            Text = "Config list",
            Values = self:RefreshConfigList(),
            AllowNull = true,
        })

-- ----- Option Search (Window-level) -----
local function attachSearchToWindow(Window, Outer, Inner)
    if not Window or not Inner then return end;
    if Window._SearchAttached then return end;
    Window._SearchAttached = true;
        section:AddButton("Load config", function()
            local name = self.Library.Options.SaveManager_ConfigList.Value
            local success, err = self:Load(name)
            if not success then
                self.Library:Notify("Failed to load config: " .. tostring(err))
                return
            end
            self.Library:Notify(string.format('Loaded config "%s"', tostring(name)))
        end)

    local SearchBox = Library:Create("TextBox", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(1, -178, 0, 4);
        Size = UDim2.new(0, 168, 0, 22);
        Font = Library.Font;
        PlaceholderText = "Search options...";
        PlaceholderColor3 = Library.DisabledTextColor;
        Text = "";
        TextColor3 = Library.FontColor;
        TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Left;
        ClearTextOnFocus = false;
        ZIndex = 80;
        Parent = Inner;
    });
        section:AddButton("Overwrite config", function()
            local name = self.Library.Options.SaveManager_ConfigList.Value
            local success, err = self:Save(name)
            if not success then
                self.Library:Notify("Failed to overwrite config: " .. tostring(err))
                return
            end
            self.Library:Notify(string.format('Overwrote config "%s"', tostring(name)))
        end)

    Library:Create("UICorner", {
        CornerRadius = UDim.new(0, 4);
        Parent = SearchBox;
    });
        section:AddButton("Delete config", function()
            local name = self.Library.Options.SaveManager_ConfigList.Value
            local success, err = self:Delete(name)
            if not success then
                self.Library:Notify("Failed to delete config: " .. tostring(err))
                return
            end
            self.Library:Notify(string.format('Deleted config "%s"', tostring(name)))
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

    Library:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6);
        Parent = SearchBox;
    });
        section:AddButton("Refresh list", function()
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

    Library:AddToRegistry(SearchBox, {
        BackgroundColor3 = "MainColor";
        BorderColor3 = "OutlineColor";
        TextColor3 = "FontColor";
    });
        section:AddButton("Set as autoload", function()
            local name = self.Library.Options.SaveManager_ConfigList.Value
            self:SaveAutoloadConfig(name)
            self.Library:Notify(string.format('Set "%s" to auto load', tostring(name)))
            if self.AutoloadConfigLabel then
                self.AutoloadConfigLabel:SetText("Current autoload config: " .. self:GetAutoloadConfig())
            end
        end)

    local ResultsOuter = Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(1, -220, 0, 30);
        Size = UDim2.new(0, 210, 0, 0);
        Visible = false;
        ZIndex = 90;
        Parent = Inner;
    });
        section:AddButton("Reset autoload", function()
            self:DeleteAutoLoadConfig()
            self.Library:Notify("Set autoload to none")
            if self.AutoloadConfigLabel then
                self.AutoloadConfigLabel:SetText("Current autoload config: none")
            end
        end)

    Library:Create("UICorner", {
        CornerRadius = UDim.new(0, 6);
        Parent = ResultsOuter;
    });
        self.AutoloadConfigLabel = section:AddLabel("Current autoload config: " .. self:GetAutoloadConfig(), true)
        self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
    end
end

    Library:AddToRegistry(ResultsOuter, {
        BackgroundColor3 = "BackgroundColor";
        BorderColor3 = "OutlineColor";
    });
Library.SaveManager = SaveManager
pcall(function()
    if getgenv then getgenv().SaveManager = SaveManager end
end)

    local ResultsScroll = Library:Create("ScrollingFrame", {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(1, -4, 1, -4);
        Position = UDim2.new(0, 2, 0, 2);
        CanvasSize = UDim2.new(0, 0, 0, 0);
        ScrollBarThickness = 3;
        ScrollBarImageColor3 = Library.AccentColor;
        ZIndex = 51;
        Parent = ResultsOuter;
    });
-- Keep Library:GetConfig / LoadConfig helpers (simple)
function Library:GetConfig()
    local data = { objects = {} }
    for idx, toggle in next, Toggles do
        if toggle.Type == "Toggle" then
            table.insert(data.objects, { type = "Toggle", idx = idx, value = toggle.Value })
        end
    end
    for idx, option in next, Options do
        if option.Type and SaveManager.Parser[option.Type] then
            table.insert(data.objects, SaveManager.Parser[option.Type].Save(idx, option))
        end
    end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    return ok and encoded or "{}"
end

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 2);
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = ResultsScroll;
    });
function Library:LoadConfig(json)
    if type(json) ~= "string" then return end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or type(decoded) ~= "table" then return end
    for _, option in ipairs(decoded.objects or {}) do
        if option.type and SaveManager.Parser[option.type] then
            task.spawn(SaveManager.Parser[option.type].Load, option.idx, option)
        end
    end
end

-- ===================== OPTION SEARCH (fixed) =====================
local function attachSearchToWindow(Window, Outer, Inner)
    if not Window or not Inner or Window._SearchAttached then return end
    Window._SearchAttached = true

    -- Use raw Instance.new for search UI so DPI/Create quirks can't blank it
    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "OptionSearch"
    SearchBox.BackgroundColor3 = Library.MainColor
    SearchBox.BorderColor3 = Library.OutlineColor
    SearchBox.BorderSizePixel = 1
    SearchBox.Position = UDim2.new(1, -180, 0, 4)
    SearchBox.Size = UDim2.new(0, 170, 0, 22)
    SearchBox.Font = Library.Font
    SearchBox.PlaceholderText = "Search options..."
    SearchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    SearchBox.TextSize = 13
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.ZIndex = 200
    SearchBox.Parent = Inner

    local sbPad = Instance.new("UIPadding")
    sbPad.PaddingLeft = UDim.new(0, 8)
    sbPad.Parent = SearchBox

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 4)
    sbCorner.Parent = SearchBox

    local Results = Instance.new("Frame")
    Results.Name = "SearchResults"
    Results.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    Results.BorderColor3 = Library.AccentColor
    Results.BorderSizePixel = 1
    Results.Position = UDim2.new(1, -230, 0, 30)
    Results.Size = UDim2.new(0, 220, 0, 0)
    Results.Visible = false
    Results.ZIndex = 210
    Results.ClipsDescendants = true
    Results.Parent = Inner

    local resCorner = Instance.new("UICorner")
    resCorner.CornerRadius = UDim.new(0, 6)
    resCorner.Parent = Results

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.Size = UDim2.new(1, -6, 1, -6)
    Scroll.Position = UDim2.new(0, 3, 0, 3)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = Library.AccentColor
    Scroll.ZIndex = 211
    Scroll.Parent = Results

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 3)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = Scroll

    local function clearResults()
        for _, c in ipairs(ResultsScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end;
        end;
    end;
        for _, c in ipairs(Scroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end

    local function collectResults(query)
        query = string.lower(tostring(query or ""));
        local results = {};

        query = string.lower(tostring(query or ""))
        local results = {}
        for idx, toggle in pairs(Toggles) do
            if type(idx) == "string" and toggle then
                local text = tostring(toggle.Text or toggle.OriginalText or idx);
                if query == "" or text:lower():find(query, 1, true) or idx:lower():find(query, 1, true) then
                    results[#results + 1] = {
                        Text = text;
                        Sub = "Toggle · " .. idx;
                        Object = toggle;
                        Kind = "Toggle";
                    };
                end;
            end;
        end;

                local text = tostring(toggle.Text or toggle.OriginalText or idx)
                if query ~= "" and (text:lower():find(query, 1, true) or idx:lower():find(query, 1, true)) then
                    results[#results + 1] = { Text = text, Sub = "Toggle", Object = toggle }
                end
            end
        end
        for idx, option in pairs(Options) do
            if type(idx) == "string" and option then
                local text = tostring(option.Text or option.OriginalText or idx);
                if query == "" or text:lower():find(query, 1, true) or idx:lower():find(query, 1, true) then
                    results[#results + 1] = {
                        Text = text;
                        Sub = (option.Type or "Option") .. " · " .. idx;
                        Object = option;
                        Kind = "Option";
                    };
                end;
            end;
        end;

        table.sort(results, function(a, b) return a.Text < b.Text end);
        return results;
    end;
                local text = tostring(option.Text or option.OriginalText or idx)
                if query ~= "" and (text:lower():find(query, 1, true) or idx:lower():find(query, 1, true)) then
                    results[#results + 1] = { Text = text, Sub = tostring(option.Type or "Option"), Object = option }
                end
            end
        end
        table.sort(results, function(a, b) return a.Text < b.Text end)
        return results
    end

    local function jumpTo(entry)
        if not entry or not entry.Object then return end;
        local label = entry.Object.TextLabel;
        if not entry or not entry.Object then return end
        local label = entry.Object.TextLabel
        if label and label.Parent then
            for _, tab in ipairs(Window.Tabs or {}) do
                if tab.TabFrame and label:IsDescendantOf(tab.TabFrame) then
                    if tab.ShowTab then
                        pcall(function() tab:ShowTab() end);
                    elseif tab.Show then
                        pcall(function() tab:Show() end);
                    end;
                    break;
                end;
            end;

            -- brief highlight flash
            local old = label.TextColor3;
                    pcall(function()
                        if tab.ShowTab then tab:ShowTab() elseif tab.Show then tab:Show() end
                    end)
                    break
                end
            end
            local old = label.TextColor3
            pcall(function()
                label.TextColor3 = Library.AccentColor;
                task.delay(0.6, function()
                    if label and label.Parent then
                        label.TextColor3 = old;
                    end;
                end);
            end);
        end;

        Library:Notify("Found: " .. tostring(entry.Text), 1.5);
        ResultsOuter.Visible = false;
        SearchBox.Text = "";
    end;
                label.TextColor3 = Library.AccentColor
                task.delay(0.7, function()
                    if label and label.Parent then label.TextColor3 = old end
                end)
            end)
        end
        Library:Notify("Found: " .. tostring(entry.Text), 1.5)
        Results.Visible = false
        SearchBox.Text = ""
    end

    local function showResults(query)
        clearResults();
        if not query or query == "" then
            ResultsOuter.Visible = false;
            ResultsOuter.Size = UDim2.new(0, 210, 0, 0);
            return;
        end;
        clearResults()
        if not query or query:gsub("%s", "") == "" then
            Results.Visible = false
            Results.Size = UDim2.new(0, 220, 0, 0)
            return
        end

        local results = collectResults(query)
        local maxShow = math.min(#results, 10)

        if maxShow == 0 then
            local empty = Instance.new("TextButton")
            empty.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
            empty.BorderSizePixel = 0
            empty.Size = UDim2.new(1, 0, 0, 28)
            empty.Font = Library.Font
            empty.Text = "  No matches"
            empty.TextColor3 = Color3.fromRGB(180, 180, 180)
            empty.TextSize = 12
            empty.TextXAlignment = Enum.TextXAlignment.Left
            empty.AutoButtonColor = false
            empty.ZIndex = 212
            empty.Parent = Scroll
            Results.Size = UDim2.new(0, 220, 0, 40)
            Results.Visible = true
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 30)
            return
        end

        local results = collectResults(query);
        local maxShow = math.min(#results, 12);
        for i = 1, maxShow do
            local entry = results[i];
            local btn = Library:Create("TextButton", {
                BackgroundColor3 = Library.MainColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, -4, 0, 28);
                Font = Library.Font;
                Text = "  " .. entry.Text;
                TextColor3 = Library.FontColor;
                TextSize = 12;
                TextXAlignment = Enum.TextXAlignment.Left;
                AutoButtonColor = false;
                ZIndex = 52;
                Parent = ResultsScroll;
            });
            Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4);
                Parent = btn;
            });
            local sub = Library:CreateLabel({
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0, 15);
                Size = UDim2.new(1, -12, 0, 12);
                Text = entry.Sub;
                TextSize = 10;
                TextColor3 = Library.DisabledTextColor;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 53;
                Parent = btn;
            });
            btn.MouseButton1Click:Connect(function()
                jumpTo(entry);
            end);
        end;
            local entry = results[i]
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.Font = Library.Font
            btn.Text = "  " .. entry.Text .. "  (" .. entry.Sub .. ")"
            btn.TextColor3 = Color3.fromRGB(240, 240, 245)
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = true
            btn.ZIndex = 212
            btn.Parent = Scroll

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = btn

        local h = math.clamp(maxShow * 30 + 6, 40, 220);
        ResultsOuter.Size = UDim2.new(0, 210, 0, h);
        ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, maxShow * 30);
        ResultsOuter.Visible = maxShow > 0;
            btn.MouseButton1Click:Connect(function()
                jumpTo(entry)
            end)
        end

        if maxShow == 0 then
            Library:Notify("No options matched", 1.2);
        end;
    end;
        local h = math.clamp(maxShow * 35 + 10, 42, 240)
        Results.Size = UDim2.new(0, 220, 0, h)
        Scroll.CanvasSize = UDim2.new(0, 0, 0, maxShow * 35)
        Results.Visible = true
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        showResults(SearchBox.Text);
    end);

    SearchBox.FocusLost:Connect(function()
        task.delay(0.2, function()
            if not SearchBox:IsFocused() then
                -- keep results if user might click; hide shortly after
            end;
        end);
    end);
        showResults(SearchBox.Text)
    end)

    -- Ctrl+F focus search
    Library:GiveSignal(InputService.InputBegan:Connect(function(input, gp)
        if gp then return end;
        if input.KeyCode == Enum.KeyCode.F and InputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F and (InputService:IsKeyDown(Enum.KeyCode.LeftControl) or InputService:IsKeyDown(Enum.KeyCode.RightControl)) then
            if Library.Toggled then
                SearchBox:CaptureFocus();
            end;
        end;
    end));
                SearchBox:CaptureFocus()
            end
        end
    end))

    Window.SearchBox = SearchBox;
end;
    Window.SearchBox = SearchBox
end

function Library.AttachOptionSearch(Window)
    if not Window then return end;
    local Inner = Window.Inner;
    local Outer = Window.Outer;
    if not Inner then return end;
    attachSearchToWindow(Window, Outer, Inner);
    if Library.Windows then
        table.insert(Library.Windows, Window);
    end;
end;
    if not Window or not Window.Inner then return end
    attachSearchToWindow(Window, Window.Outer, Window.Inner)
end

-- Also try attach on any already-created window
task.defer(function()
    pcall(function()
        if Library.Window and not Library.Window._SearchAttached then
            Library.AttachOptionSearch(Library.Window);
        end;
    end);
end);

            Library.AttachOptionSearch(Library.Window)
        end
    end)
end)

return Library
