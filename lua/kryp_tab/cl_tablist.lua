if not CLIENT then return end

KrypTab = KrypTab or {}
local FT = KrypTab
local CONFIG = FT.Config or {}
local COLORS = CONFIG.Colors or {}

local UI = {
    Material = nil,
    Fetching = false,
    SortMode = "citoyens"
}

local function C(name, fallback)
    return COLORS[name] or fallback
end

local function S(value)
    return math.max(1, math.floor(value * math.Clamp(ScrH() / 1080, 0.72, 1.16)))
end

local function CreateFonts()
    surface.CreateFont("KrypTab.Server", {
        font = "Roboto",
        size = S(27),
        weight = 800,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.ServerCount", {
        font = "Roboto",
        size = S(14),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Player", {
        font = "Roboto",
        size = S(15),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Row", {
        font = "Roboto",
        size = S(14),
        weight = 550,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Small", {
        font = "Roboto",
        size = S(12),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.PopupTitle", {
        font = "Roboto",
        size = S(22),
        weight = 800,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.PopupTab", {
        font = "Roboto",
        size = S(14),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Action", {
        font = "Roboto",
        size = S(13),
        weight = 650,
        antialias = true,
        extended = true
    })
end

CreateFonts()
hook.Add("OnScreenSizeChanged", "KrypTab.RecreateFonts", CreateFonts)

local function GetServerName()
    if isstring(CONFIG.ServerName) and string.Trim(CONFIG.ServerName) ~= "" then
        return CONFIG.ServerName
    end

    return GetHostName()
end

local function GetPlayerJob(ply)
    if DarkRP and ply.getDarkRPVar then
        local job = ply:getDarkRPVar("job")
        if isstring(job) and job ~= "" then
            return job
        end
    end

    local teamName = team.GetName(ply:Team())
    if isstring(teamName) and teamName ~= "" and teamName ~= "Unassigned" then
        return teamName
    end

    return "Citoyen"
end

local function GetPlayerRank(ply)
    local group = ply:GetUserGroup()
    if not isstring(group) or group == "" then
        return "user"
    end

    return group
end

local function GetPlayerTime(ply)
    if isfunction(ply.sam_get_play_time) then
        local ok, value = pcall(ply.sam_get_play_time, ply)
        if ok and isnumber(value) then return math.max(0, value) end
    end

    if isfunction(ply.GetUTimeTotalTime) then
        local ok, value = pcall(ply.GetUTimeTotalTime, ply)
        if ok and isnumber(value) then return math.max(0, value) end
    end

    return math.max(0, ply:GetNWInt("playtime", 0))
end

local function FormatPlayTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if hours >= 100 then
        return string.format("%dh", hours)
    end

    return string.format("%02dh %02dm", hours, minutes)
end

local function Notify(text, kind)
    notification.AddLegacy(text, kind or NOTIFY_GENERIC, 2.5)
end

local function EnsureUIMaterial(force)
    local path = CONFIG.UIImageDataPath or "kryp_tab/L0bpoDh.png"

    if not force and UI.Material and not UI.Material:IsError() then return end

    if not force and file.Exists(path, "DATA") and file.Size(path, "DATA") > 1024 then
        UI.Material = Material("../data/" .. path, "smooth noclamp")
        if UI.Material and not UI.Material:IsError() then return end
    end

    if UI.Fetching then return end
    if not isstring(CONFIG.UIImageURL) or CONFIG.UIImageURL == "" then return end

    UI.Fetching = true
    file.CreateDir("kryp_tab")

    http.Fetch(CONFIG.UIImageURL, function(body, length, _, code)
        UI.Fetching = false

        if code and code >= 400 then return end
        if not body or (length or #body) < 1024 then return end

        file.Write(path, body)
        UI.Material = Material("../data/" .. path, "smooth noclamp")
    end, function()
        UI.Fetching = false
    end)
end

EnsureUIMaterial(false)

local function GetPanelRect()
    local aspect = (CONFIG.UIImageCrop and CONFIG.UIImageCrop.aspect) or 1.805
    local maxW = ScrW() * 0.965
    local maxH = ScrH() * 0.88
    local w = maxW
    local h = w / aspect

    if h > maxH then
        h = maxH
        w = h * aspect
    end

    return (ScrW() - w) * 0.5, (ScrH() - h) * 0.5, w, h
end

local function DrawFallbackPanel(x, y, w, h)
    draw.RoundedBox(S(22), x, y, w, h, C("Background", Color(8, 13, 21, 248)))
    draw.RoundedBox(S(12), x + w * 0.03, y + h * 0.16, w * 0.94, h * 0.085, C("Header", Color(23, 31, 45, 245)))
    draw.RoundedBox(S(10), x + w * 0.03, y + h * 0.285, w * 0.94, h * 0.07, C("Header", Color(23, 31, 45, 245)))
end

local function DrawUIBackplate(x, y, w, h)
    surface.SetDrawColor(0, 0, 0, 125)
    surface.DrawRect(0, 0, ScrW(), ScrH())

    if UI.Material and not UI.Material:IsError() then
        local crop = CONFIG.UIImageCrop or {}
        surface.SetMaterial(UI.Material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectUV(
            x,
            y,
            w,
            h,
            crop.u0 or 0,
            crop.v0 or 0,
            crop.u1 or 1,
            crop.v1 or 1
        )
    else
        DrawFallbackPanel(x, y, w, h)
    end
end

local function IsSAMLoaded()
    return sam ~= nil or SAM ~= nil
end

local function HasSAMPermission(permission)
    if not IsSAMLoaded() then return false end

    local client = LocalPlayer()
    if not IsValid(client) or not isstring(permission) or permission == "" then return false end

    if isfunction(client.HasPermission) then
        local ok, allowed = pcall(client.HasPermission, client, permission)
        if ok then return allowed == true end
    end

    return false
end

local function GetSAMActions()
    local result = {}

    for _, action in ipairs(CONFIG.SAMActions or {}) do
        if istable(action) and HasSAMPermission(action.permission or action.command) then
            result[#result + 1] = action
        end
    end

    return result
end

local function RunSAMAction(action, target, duration, reason)
    if not IsValid(target) or not istable(action) then return end
    if not HasSAMPermission(action.permission or action.command) then return end

    local command = tostring(action.command or "")
    if command == "" then return end

    local steamID = target:SteamID()

    if action.duration and action.reason then
        RunConsoleCommand("sam", command, steamID, tostring(duration or "0"), tostring(reason or ""))
    elseif action.duration then
        RunConsoleCommand("sam", command, steamID, tostring(duration or "0"))
    elseif action.reason then
        RunConsoleCommand("sam", command, steamID, tostring(reason or ""))
    else
        RunConsoleCommand("sam", command, steamID)
    end
end

local function PromptSAMAction(action, target)
    if not IsValid(target) then return end

    if action.duration then
        Derma_StringRequest(
            action.label .. " - " .. target:Nick(),
            "Durée SAM (ex: 10m, 1h ou 0) :",
            "0",
            function(duration)
                if action.reason then
                    Derma_StringRequest(
                        action.label .. " - " .. target:Nick(),
                        "Raison :",
                        "",
                        function(reason)
                            RunSAMAction(action, target, duration, reason)
                        end
                    )
                else
                    RunSAMAction(action, target, duration)
                end
            end
        )
        return
    end

    if action.reason then
        Derma_StringRequest(
            action.label .. " - " .. target:Nick(),
            "Raison :",
            "",
            function(reason)
                RunSAMAction(action, target, nil, reason)
            end
        )
        return
    end

    RunSAMAction(action, target)
end

local function CreateFlatButton(parent, text, onClick, accent)
    local button = vgui.Create("DButton", parent)
    button:SetText("")
    button:SetCursor("hand")
    button.DoClick = onClick
    button.Paint = function(self, w, h)
        local hovered = self:IsHovered()
        local bg

        if accent then
            bg = hovered and Color(255, 103, 50, 255) or C("Accent", Color(255, 83, 21, 255))
        else
            bg = hovered and C("PanelHover", Color(22, 30, 44, 250)) or C("Header", Color(23, 31, 45, 245))
        end

        draw.RoundedBox(S(7), 0, 0, w, h, bg)
        draw.SimpleText(text, "KrypTab.Action", w * 0.5, h * 0.5, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return button
end

function FT:OpenPlayerActions(target)
    if not IsValid(target) or not IsValid(self.Frame) then return end

    if IsValid(self.PlayerPopup) then
        self.PlayerPopup:Remove()
    end

    local frame = self.Frame
    local popup = vgui.Create("DPanel", frame)
    self.PlayerPopup = popup

    local pw = math.min(S(720), ScrW() * 0.48)
    local ph = math.min(S(520), ScrH() * 0.62)
    popup:SetSize(pw, ph)
    popup:SetPos((ScrW() - pw) * 0.5, (ScrH() - ph) * 0.5)
    popup:SetAlpha(0)
    popup:AlphaTo(255, 0.12, 0)
    popup:SetMouseInputEnabled(true)
    popup:SetKeyboardInputEnabled(true)

    popup.Paint = function(self, w, h)
        draw.RoundedBox(S(14), 0, 0, w, h, Color(9, 14, 23, 252))
        surface.SetDrawColor(C("Divider", Color(57, 69, 89, 180)))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))
        draw.RoundedBox(S(8), S(18), S(94), w - S(36), S(48), Color(17, 24, 36, 245))
    end

    local avatar = vgui.Create("AvatarImage", popup)
    avatar:SetSize(S(54), S(54))
    avatar:SetPos(S(22), S(20))
    avatar:SetPlayer(target, 64)

    local title = vgui.Create("DLabel", popup)
    title:SetFont("KrypTab.PopupTitle")
    title:SetTextColor(C("Text", color_white))
    title:SetText(target:Nick())
    title:SetPos(S(90), S(18))
    title:SetSize(pw - S(160), S(30))

    local steam = vgui.Create("DLabel", popup)
    steam:SetFont("KrypTab.Small")
    steam:SetTextColor(C("Muted", Color(161, 171, 190)))
    steam:SetText(target:SteamID() .. "  •  " .. GetPlayerRank(target))
    steam:SetPos(S(91), S(49))
    steam:SetSize(pw - S(170), S(22))

    local close = CreateFlatButton(popup, "×", function()
        if IsValid(popup) then popup:Remove() end
    end, true)
    close:SetSize(S(42), S(42))
    close:SetPos(pw - S(60), S(20))

    local samActions = GetSAMActions()
    local hasManagement = #samActions > 0
    local activeTab = hasManagement and "gestion" or "autres"

    local content = vgui.Create("DPanel", popup)
    content:SetPos(S(20), S(155))
    content:SetSize(pw - S(40), ph - S(175))
    content.Paint = nil

    local function ClearContent()
        for _, child in ipairs(content:GetChildren()) do
            child:Remove()
        end
    end

    local gestionButton
    local otherButton

    local function RebuildContent()
        ClearContent()

        if activeTab == "gestion" and hasManagement then
            local grid = vgui.Create("DIconLayout", content)
            grid:Dock(FILL)
            grid:SetSpaceX(S(10))
            grid:SetSpaceY(S(10))

            local columns = 3
            local itemW = math.floor((content:GetWide() - S(20)) / columns)

            for _, action in ipairs(samActions) do
                local btn = grid:Add("DButton")
                btn:SetSize(itemW, S(48))
                btn:SetText("")
                btn:SetCursor("hand")
                btn.Paint = function(self, w, h)
                    local hover = self:IsHovered()
                    draw.RoundedBox(S(7), 0, 0, w, h, hover and C("AccentSoft", Color(255, 83, 21, 38)) or Color(20, 28, 41, 245))
                    surface.SetDrawColor(hover and C("Accent", Color(255, 83, 21)) or C("Divider", Color(57, 69, 89)))
                    surface.DrawOutlinedRect(0, 0, w, h, S(1))
                    draw.SimpleText(action.label, "KrypTab.Action", w * 0.5, h * 0.5, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                btn.DoClick = function()
                    PromptSAMAction(action, target)
                end
            end

            return
        end

        local universal = {
            {
                label = "Copier le SteamID",
                callback = function()
                    if not IsValid(target) then return end
                    SetClipboardText(target:SteamID())
                    Notify("SteamID copié : " .. target:SteamID())
                end
            },
            {
                label = "Voir le profil Steam",
                callback = function()
                    if not IsValid(target) then return end
                    gui.OpenURL("https://steamcommunity.com/profiles/" .. target:SteamID64())
                end
            },
            {
                label = "Ajouter aux contacts",
                callback = function()
                    if not IsValid(target) then return end
                    gui.OpenURL("steam://friends/add/" .. target:SteamID64())
                end
            }
        }

        for i, item in ipairs(universal) do
            local btn = CreateFlatButton(content, item.label, item.callback, i == 3)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, S(12))
            btn:SetTall(S(52))
        end
    end

    if hasManagement then
        gestionButton = vgui.Create("DButton", popup)
        gestionButton:SetText("")
        gestionButton:SetCursor("hand")
        gestionButton:SetPos(S(24), S(96))
        gestionButton:SetSize(S(170), S(44))
        gestionButton.Paint = function(self, w, h)
            local selected = activeTab == "gestion"
            draw.SimpleText("Gestion", "KrypTab.PopupTab", S(14), h * 0.5, selected and C("Text", color_white) or C("Muted", Color(161, 171, 190)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if selected then
                surface.SetDrawColor(C("Accent", Color(255, 83, 21)))
                surface.DrawRect(0, h - S(3), w, S(3))
            end
        end
        gestionButton.DoClick = function()
            activeTab = "gestion"
            RebuildContent()
        end
    end

    otherButton = vgui.Create("DButton", popup)
    otherButton:SetText("")
    otherButton:SetCursor("hand")
    otherButton:SetPos(hasManagement and S(205) or S(24), S(96))
    otherButton:SetSize(S(170), S(44))
    otherButton.Paint = function(self, w, h)
        local selected = activeTab == "autres"
        draw.SimpleText("Autres", "KrypTab.PopupTab", S(14), h * 0.5, selected and C("Text", color_white) or C("Muted", Color(161, 171, 190)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if selected then
            surface.SetDrawColor(C("Accent", Color(255, 83, 21)))
            surface.DrawRect(0, h - S(3), w, S(3))
        end
    end
    otherButton.DoClick = function()
        activeTab = "autres"
        RebuildContent()
    end

    RebuildContent()
end

local function SortPlayers(players)
    local mode = UI.SortMode

    table.sort(players, function(a, b)
        if not IsValid(a) then return false end
        if not IsValid(b) then return true end

        if mode == "metier" then
            return string.lower(GetPlayerJob(a)) < string.lower(GetPlayerJob(b))
        elseif mode == "rang" then
            return string.lower(GetPlayerRank(a)) < string.lower(GetPlayerRank(b))
        elseif mode == "temps" then
            return GetPlayerTime(a) > GetPlayerTime(b)
        elseif mode == "kd" then
            local akd = a:Frags() / math.max(1, a:Deaths())
            local bkd = b:Frags() / math.max(1, b:Deaths())
            return akd > bkd
        elseif mode == "ping" then
            return a:Ping() < b:Ping()
        elseif mode == "profil" then
            return a:SteamID64() < b:SteamID64()
        end

        return string.lower(a:Nick()) < string.lower(b:Nick())
    end)
end

local function PlayerMatchesSearch(ply, query)
    if query == "" then return true end
    query = string.lower(query)

    local values = {
        ply:Nick(),
        ply:SteamID(),
        ply:SteamID64(),
        GetPlayerJob(ply),
        GetPlayerRank(ply)
    }

    for _, value in ipairs(values) do
        value = tostring(value or "")
        if string.find(string.lower(value), query, 1, true) then
            return true
        end
    end

    return false
end

local function CreatePlayerRow(parent, ply, panelW, panelH)
    local row = vgui.Create("DButton", parent)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, S(7))
    row:SetTall(math.max(S(62), panelH * 0.078))
    row:SetText("")
    row:SetCursor("hand")

    local avatarSize = math.floor(row:GetTall() * 0.64)
    local avatar = vgui.Create("AvatarImage", row)
    avatar:SetSize(avatarSize, avatarSize)
    avatar:SetPos(S(15), (row:GetTall() - avatarSize) * 0.5)
    avatar:SetPlayer(ply, 64)

    row.Paint = function(self, w, h)
        if not IsValid(ply) then return end

        local hovered = self:IsHovered()
        draw.RoundedBox(S(7), 0, 0, w, h, hovered and Color(23, 31, 45, 245) or Color(12, 18, 29, 228))

        if hovered then
            surface.SetDrawColor(C("Accent", Color(255, 83, 21)))
            surface.DrawRect(0, S(8), S(3), h - S(16))
        end

        local nameX = S(78)
        draw.SimpleText(ply:Nick(), "KrypTab.Player", nameX, h * 0.37, C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(ply:SteamID(), "KrypTab.Small", nameX, h * 0.70, C("Muted", Color(161, 171, 190)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText(GetPlayerJob(ply), "KrypTab.Row", w * 0.235, h * 0.5, C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(GetPlayerRank(ply), "KrypTab.Row", w * 0.405, h * 0.5, C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(FormatPlayTime(GetPlayerTime(ply)), "KrypTab.Row", w * 0.565, h * 0.5, C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(ply:Frags()), "KrypTab.Row", w * 0.735, h * 0.5, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(ply:Deaths()), "KrypTab.Row", w * 0.845, h * 0.5, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(math.max(0, ply:Ping())), "KrypTab.Row", w * 0.955, h * 0.5, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    row.DoClick = function()
        if IsValid(ply) then
            FT:OpenPlayerActions(ply)
        end
    end

    return row
end

function FT:BuildPlayerList()
    if not IsValid(self.PlayerCanvas) then return end

    for _, child in ipairs(self.PlayerCanvas:GetChildren()) do
        child:Remove()
    end

    local players = player.GetAll()
    SortPlayers(players)

    local query = ""
    if IsValid(self.SearchEntry) then
        query = string.Trim(self.SearchEntry:GetValue() or "")
    end

    local count = 0
    local _, _, panelW, panelH = GetPanelRect()

    for _, ply in ipairs(players) do
        if IsValid(ply) and PlayerMatchesSearch(ply, query) then
            CreatePlayerRow(self.PlayerCanvas, ply, panelW, panelH)
            count = count + 1
        end
    end

    if count == 0 then
        local empty = vgui.Create("DLabel", self.PlayerCanvas)
        empty:Dock(TOP)
        empty:SetTall(S(72))
        empty:SetFont("KrypTab.Row")
        empty:SetTextColor(C("Muted", Color(161, 171, 190)))
        empty:SetContentAlignment(5)
        empty:SetText("Aucun joueur ne correspond à la recherche.")
    end
end

local function AddSortHitbox(frame, x, y, w, h, mode)
    local button = vgui.Create("DButton", frame)
    button:SetPos(x, y)
    button:SetSize(w, h)
    button:SetText("")
    button:SetCursor("hand")
    button.Paint = function() end
    button.DoClick = function()
        UI.SortMode = mode
        FT:BuildPlayerList()
    end
end

function FT:OpenSettingsMenu()
    local menu = DermaMenu()
    menu:AddOption("Rafraîchir l'interface", function()
        EnsureUIMaterial(true)
        FT:BuildPlayerList()
    end)
    menu:AddOption("Réinitialiser la recherche", function()
        if IsValid(FT.SearchEntry) then
            FT.SearchEntry:SetText("")
            FT:BuildPlayerList()
        end
    end)
    menu:AddSpacer()
    menu:AddOption("Copier le nom du serveur", function()
        SetClipboardText(GetServerName())
    end)
    menu:Open()
end

function FT:Open()
    if IsValid(self.Frame) then
        self.Frame:Remove()
    end

    EnsureUIMaterial(false)

    local frame = vgui.Create("DFrame")
    self.Frame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetSizable(false)
    frame:SetAlpha(0)
    frame:MakePopup()
    frame:AlphaTo(255, CONFIG.AnimationTime or 0.14, 0)

    local panelX, panelY, panelW, panelH = GetPanelRect()

    frame.Paint = function(_, w, h)
        DrawUIBackplate(panelX, panelY, panelW, panelH)
    end

    frame.Think = function()
        -- Le TAB reste visible uniquement tant que la touche TAB est maintenue.
        if not input.IsKeyDown(KEY_TAB) then
            FT:Close()
        end
    end

    local serverName = vgui.Create("DLabel", frame)
    serverName:SetFont("KrypTab.Server")
    serverName:SetTextColor(C("Text", color_white))
    serverName:SetText(GetServerName())
    serverName:SetPos(panelX + panelW * 0.035, panelY + panelH * 0.045)
    serverName:SetSize(panelW * 0.48, S(36))

    local playerCount = vgui.Create("DLabel", frame)
    playerCount:SetFont("KrypTab.ServerCount")
    playerCount:SetTextColor(C("Muted", Color(161, 171, 190)))
    playerCount:SetPos(panelX + panelW * 0.036, panelY + panelH * 0.087)
    playerCount:SetSize(panelW * 0.42, S(24))
    playerCount.Think = function(self)
        self:SetText(string.format("%d / %d joueurs en ligne", player.GetCount(), game.MaxPlayers()))
    end

    local search = vgui.Create("DTextEntry", frame)
    self.SearchEntry = search
    search:SetPos(panelX + panelW * 0.646, panelY + panelH * 0.057)
    search:SetSize(panelW * 0.217, panelH * 0.064)
    search:SetFont("KrypTab.Row")
    search:SetTextColor(C("Text", color_white))
    search:SetPlaceholderText("Rechercher...")
    search:SetUpdateOnType(true)
    search:SetDrawLanguageID(false)
    search.Paint = function(self, w, h)
        draw.RoundedBox(S(8), 0, 0, w, h, Color(26, 34, 49, 248))
        surface.SetDrawColor(C("Divider", Color(57, 69, 89, 180)))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))
        self:DrawTextEntryText(C("Text", color_white), C("Accent", Color(255, 83, 21)), C("Text", color_white))
    end
    search.OnValueChange = function()
        FT:BuildPlayerList()
    end

    local settings = vgui.Create("DButton", frame)
    settings:SetText("")
    settings:SetCursor("hand")
    settings:SetPos(panelX + panelW * 0.874, panelY + panelH * 0.057)
    settings:SetSize(panelW * 0.043, panelH * 0.064)
    settings.Paint = function() end
    settings.DoClick = function()
        FT:OpenSettingsMenu()
    end

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetCursor("hand")
    close:SetPos(panelX + panelW * 0.928, panelY + panelH * 0.057)
    close:SetSize(panelW * 0.045, panelH * 0.064)
    close.Paint = function() end
    close.DoClick = function()
        FT:Close()
    end

    local tabsX = panelX + panelW * 0.03
    local tabsY = panelY + panelH * 0.16
    local tabsW = panelW * 0.94
    local tabsH = panelH * 0.085

    local definitions = {
        {0.00, 0.15, "citoyens"},
        {0.15, 0.13, "profil"},
        {0.28, 0.13, "metier"},
        {0.41, 0.13, "rang"},
        {0.54, 0.16, "temps"},
        {0.70, 0.12, "kd"},
        {0.82, 0.18, "ping"}
    }

    for _, tab in ipairs(definitions) do
        AddSortHitbox(frame, tabsX + tabsW * tab[1], tabsY, tabsW * tab[2], tabsH, tab[3])
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(panelX + panelW * 0.03, panelY + panelH * 0.365)
    scroll:SetSize(panelW * 0.94, panelH * 0.545)
    self.PlayerScroll = scroll
    self.PlayerCanvas = scroll:GetCanvas()

    local vbar = scroll:GetVBar()
    vbar:SetWide(S(5))
    vbar.Paint = function() end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, w, h)
        draw.RoundedBox(S(3), 0, 0, w, h, C("Divider", Color(57, 69, 89, 180)))
    end

    self:BuildPlayerList()

    timer.Remove("KrypTab.Refresh")
    timer.Create("KrypTab.Refresh", CONFIG.RefreshInterval or 1, 0, function()
        if not IsValid(FT.Frame) then
            timer.Remove("KrypTab.Refresh")
            return
        end

        FT:BuildPlayerList()
    end)
end

function FT:Close()
    timer.Remove("KrypTab.Refresh")

    if not IsValid(self.Frame) then return end

    local frame = self.Frame
    self.Frame = nil
    self.PlayerPopup = nil

    frame:AlphaTo(0, 0.08, 0, function()
        if IsValid(frame) then frame:Remove() end
    end)
end

hook.Add("ScoreboardShow", "KrypTab.Open", function()
    FT:Open()
    return true
end)

hook.Add("ScoreboardHide", "KrypTab.Close", function()
    FT:Close()
end)

hook.Add("ShutDown", "KrypTab.Cleanup", function()
    timer.Remove("KrypTab.Refresh")
end)
