if not CLIENT then return end

KrypTab = KrypTab or {}
local FT = KrypTab
local CONFIG = FT.Config or {}
local COLORS = CONFIG.Colors or {}

local function C(name, fallback)
    return COLORS[name] or fallback
end

local function Scale(value)
    return math.max(1, math.floor(value * math.Clamp(ScrH() / 1080, 0.72, 1.15)))
end

local function CreateFonts()
    surface.CreateFont("KrypTab.Server", {
        font = "Roboto",
        size = Scale(28),
        weight = 800,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Subtitle", {
        font = "Roboto",
        size = Scale(15),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Header", {
        font = "Roboto",
        size = Scale(13),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Player", {
        font = "Roboto",
        size = Scale(16),
        weight = 650,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Small", {
        font = "Roboto",
        size = Scale(13),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("KrypTab.Button", {
        font = "Roboto",
        size = Scale(11),
        weight = 750,
        antialias = true,
        extended = true
    })
end

CreateFonts()
hook.Add("OnScreenSizeChanged", "KrypTab.RecreateFonts", CreateFonts)

local function RoundedBox(radius, x, y, w, h, color)
    draw.RoundedBox(radius, x, y, w, h, color)
end

local function GetServerName()
    if isstring(CONFIG.ServerName) and string.Trim(CONFIG.ServerName) ~= "" then
        return CONFIG.ServerName
    end

    return GetHostName()
end

local function GetPlayerRole(ply)
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

    local group = ply:GetUserGroup()
    if isstring(group) and group ~= "" then
        return group
    end

    return "Joueur"
end

local function OpenPlayerProfile(ply)
    if not IsValid(ply) then return end

    local steamID64 = ply:SteamID64()
    if not steamID64 or steamID64 == "" then return end

    gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID64)
end

local function Notify(text, notifyType)
    notification.AddLegacy(text, notifyType or NOTIFY_GENERIC, 2.5)
    surface.PlaySound("buttons/button15.wav")
end

local function MakeButton(parent, text, width, onClick)
    local button = vgui.Create("DButton", parent)
    button:SetWide(width)
    button:SetText("")
    button:SetCursor("hand")
    button.Label = text
    button.DoClick = onClick

    button.Paint = function(self, w, h)
        local hovered = self:IsHovered()
        local bg = hovered and C("AccentSoft", Color(105, 111, 255, 35)) or Color(255, 255, 255, 7)
        RoundedBox(Scale(6), 0, 0, w, h, bg)
        draw.SimpleText(self.Label or text, "KrypTab.Button", w / 2, h / 2, hovered and C("Text", color_white) or C("Muted", Color(145, 145, 145)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return button
end

local function ClearPanel(panel)
    if not IsValid(panel) then return end
    for _, child in ipairs(panel:GetChildren()) do
        child:Remove()
    end
end

local function PlayerMatchesSearch(ply, query)
    if query == "" then return true end

    query = string.lower(query)
    local fields = {
        ply:Nick(),
        ply:SteamID(),
        ply:GetUserGroup(),
        GetPlayerRole(ply)
    }

    for _, value in ipairs(fields) do
        if isstring(value) and string.find(string.lower(value), query, 1, true) then
            return true
        end
    end

    return false
end

local function CreatePlayerRow(parent, ply)
    if not IsValid(ply) then return end

    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, Scale(8))
    row:SetTall(Scale(66))
    row.Paint = function(self, w, h)
        local bg = self:IsHovered() and C("PanelHover", Color(27, 29, 35)) or C("Panel", Color(21, 22, 27))
        RoundedBox(Scale(8), 0, 0, w, h, bg)

        local teamColor = team.GetColor(ply:Team()) or C("Accent", Color(105, 111, 255))
        surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, 220)
        surface.DrawRect(0, Scale(10), Scale(3), h - Scale(20))
    end

    local avatar = vgui.Create("AvatarImage", row)
    avatar:SetSize(Scale(42), Scale(42))
    avatar:SetPos(Scale(16), Scale(12))
    avatar:SetPlayer(ply, 64)

    local name = vgui.Create("DLabel", row)
    name:SetFont("KrypTab.Player")
    name:SetTextColor(C("Text", color_white))
    name:SetText(ply:Nick())
    name:SetPos(Scale(72), Scale(12))
    name:SetSize(Scale(240), Scale(22))

    local role = vgui.Create("DLabel", row)
    role:SetFont("KrypTab.Small")
    role:SetTextColor(C("Muted", Color(143, 147, 158)))
    role:SetText(GetPlayerRole(ply))
    role:SetPos(Scale(72), Scale(35))
    role:SetSize(Scale(240), Scale(19))

    local stats = vgui.Create("DPanel", row)
    stats:SetPaintBackground(false)
    stats:SetPos(Scale(330), Scale(9))
    stats:SetSize(Scale(260), Scale(48))

    local function StatLabel(x, title, valueFunc)
        local label = vgui.Create("DLabel", stats)
        label:SetFont("KrypTab.Small")
        label:SetTextColor(C("Muted", Color(143, 147, 158)))
        label:SetPos(x, 0)
        label:SetSize(Scale(75), Scale(48))
        label:SetContentAlignment(5)
        label.Think = function(self)
            if not IsValid(ply) then return end
            self:SetText(title .. "\n" .. tostring(valueFunc()))
        end
    end

    StatLabel(0, "K", function() return ply:Frags() end)
    StatLabel(Scale(80), "M", function() return ply:Deaths() end)
    StatLabel(Scale(160), "PING", function() return math.max(0, ply:Ping()) end)

    local actions = vgui.Create("DPanel", row)
    actions:Dock(RIGHT)
    actions:DockMargin(0, Scale(14), Scale(14), Scale(14))
    actions:SetWide(Scale(276))
    actions:SetPaintBackground(false)

    local mute = MakeButton(actions, "MUET", Scale(76), function(self)
        if not IsValid(ply) or ply == LocalPlayer() then return end
        ply:SetMuted(not ply:IsMuted())
        self.Label = ply:IsMuted() and "RÉACTIVER" or "MUET"
        Notify(ply:IsMuted() and (ply:Nick() .. " a été rendu muet.") or (ply:Nick() .. " a été réactivé."))
    end)
    mute:Dock(RIGHT)
    mute:DockMargin(Scale(6), 0, 0, 0)
    mute.Think = function(self)
        if not IsValid(ply) then return end
        if ply == LocalPlayer() then
            self.Label = "VOUS"
            self:SetEnabled(false)
            self:SetCursor("arrow")
        else
            self.Label = ply:IsMuted() and "RÉACTIVER" or "MUET"
        end
    end

    local copy = MakeButton(actions, "COPIER", Scale(82), function()
        if not IsValid(ply) then return end
        SetClipboardText(ply:SteamID())
        Notify("SteamID copié : " .. ply:SteamID())
    end)
    copy:Dock(RIGHT)
    copy:DockMargin(Scale(6), 0, 0, 0)

    local profile = MakeButton(actions, "PROFIL", Scale(82), function()
        OpenPlayerProfile(ply)
    end)
    profile:Dock(RIGHT)

    return row
end

function FT:BuildPlayerList()
    if not IsValid(self.PlayerCanvas) then return end

    ClearPanel(self.PlayerCanvas)

    local players = player.GetAll()
    table.sort(players, function(a, b)
        if a == LocalPlayer() then return true end
        if b == LocalPlayer() then return false end
        return string.lower(a:Nick()) < string.lower(b:Nick())
    end)

    local query = ""
    if IsValid(self.SearchEntry) then
        query = string.Trim(self.SearchEntry:GetValue() or "")
    end

    local count = 0
    for _, ply in ipairs(players) do
        if IsValid(ply) and PlayerMatchesSearch(ply, query) then
            CreatePlayerRow(self.PlayerCanvas, ply)
            count = count + 1
        end
    end

    if count == 0 then
        local empty = vgui.Create("DLabel", self.PlayerCanvas)
        empty:Dock(TOP)
        empty:SetTall(Scale(80))
        empty:SetFont("KrypTab.Small")
        empty:SetTextColor(C("Muted", Color(143, 147, 158)))
        empty:SetContentAlignment(5)
        empty:SetText("Aucun joueur ne correspond à la recherche.")
    end
end

function FT:Open()
    if IsValid(self.Frame) then
        self.Frame:Remove()
    end

    local frameW = math.min(ScrW() * 0.84, Scale(1320))
    local frameH = math.min(ScrH() * 0.78, Scale(820))
    local targetX = (ScrW() - frameW) / 2
    local targetY = (ScrH() - frameH) / 2

    local frame = vgui.Create("DFrame")
    self.Frame = frame
    frame:SetSize(frameW, frameH)
    frame:SetPos(targetX, targetY + Scale(18))
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetSizable(false)
    frame:SetAlpha(0)
    frame:MakePopup()
    frame.Paint = function(_, w, h)
        RoundedBox(Scale(12), 0, 0, w, h, C("Background", Color(14, 15, 18, 248)))
        RoundedBox(Scale(12), 0, 0, w, Scale(112), C("Header", Color(18, 19, 23)))
        surface.SetDrawColor(C("Divider", Color(43, 45, 54)))
        surface.DrawRect(Scale(24), Scale(111), w - Scale(48), 1)
    end

    frame:AlphaTo(255, CONFIG.AnimationTime or 0.16, 0)
    frame:MoveTo(targetX, targetY, CONFIG.AnimationTime or 0.16, 0, 0.25)

    local serverName = vgui.Create("DLabel", frame)
    serverName:SetFont("KrypTab.Server")
    serverName:SetTextColor(C("Text", color_white))
    serverName:SetText(GetServerName())
    serverName:SetPos(Scale(28), Scale(23))
    serverName:SetSize(frameW * 0.48, Scale(38))
    serverName.Think = function(self)
        self:SetText(GetServerName())
    end

    local playerCount = vgui.Create("DLabel", frame)
    playerCount:SetFont("KrypTab.Subtitle")
    playerCount:SetTextColor(C("Muted", Color(143, 147, 158)))
    playerCount:SetPos(Scale(29), Scale(62))
    playerCount:SetSize(frameW * 0.45, Scale(24))
    playerCount.Think = function(self)
        self:SetText(string.format("%d / %d joueurs en ligne", player.GetCount(), game.MaxPlayers()))
    end

    local close = MakeButton(frame, "FERMER", Scale(84), function()
        FT:Close()
    end)
    close:SetTall(Scale(34))
    close:SetPos(frameW - Scale(112), Scale(38))

    local linkRight = frameW - Scale(126)
    if istable(CONFIG.Links) then
        for i = #CONFIG.Links, 1, -1 do
            local link = CONFIG.Links[i]
            if istable(link) and isstring(link.label) and isstring(link.url) and string.Trim(link.url) ~= "" then
                local button = MakeButton(frame, link.label, Scale(92), function()
                    gui.OpenURL(link.url)
                end)
                button:SetTall(Scale(34))
                linkRight = linkRight - Scale(100)
                button:SetPos(linkRight, Scale(38))
            end
        end
    end

    local search = vgui.Create("DTextEntry", frame)
    self.SearchEntry = search
    search:SetPos(Scale(28), Scale(130))
    search:SetSize(Scale(310), Scale(38))
    search:SetFont("KrypTab.Small")
    search:SetTextColor(C("Text", color_white))
    search:SetPlaceholderText("Rechercher un joueur...")
    search:SetUpdateOnType(true)
    search.Paint = function(self, w, h)
        RoundedBox(Scale(7), 0, 0, w, h, C("Panel", Color(21, 22, 27)))
        self:DrawTextEntryText(C("Text", color_white), C("Accent", Color(105, 111, 255)), C("Text", color_white))
    end
    search.OnValueChange = function()
        FT:BuildPlayerList()
    end

    local columnHeader = vgui.Create("DPanel", frame)
    columnHeader:SetPos(Scale(28), Scale(178))
    columnHeader:SetSize(frameW - Scale(56), Scale(34))
    columnHeader.Paint = function(_, w, h)
        draw.SimpleText("JOUEUR", "KrypTab.Header", Scale(72), h / 2, C("Muted", Color(143, 147, 158)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("STATISTIQUES", "KrypTab.Header", Scale(330), h / 2, C("Muted", Color(143, 147, 158)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("ACTIONS", "KrypTab.Header", w - Scale(262), h / 2, C("Muted", Color(143, 147, 158)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(Scale(28), Scale(214))
    scroll:SetSize(frameW - Scale(56), frameH - Scale(264))
    self.PlayerScroll = scroll
    self.PlayerCanvas = scroll:GetCanvas()

    local vbar = scroll:GetVBar()
    vbar:SetWide(Scale(5))
    vbar.Paint = function() end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, w, h)
        RoundedBox(Scale(3), 0, 0, w, h, C("Divider", Color(43, 45, 54)))
    end

    local footer = vgui.Create("DLabel", frame)
    footer:SetFont("KrypTab.Small")
    footer:SetTextColor(C("Muted", Color(143, 147, 158)))
    footer:SetText(CONFIG.FooterText or "")
    footer:SetContentAlignment(5)
    footer:SetPos(Scale(28), frameH - Scale(40))
    footer:SetSize(frameW - Scale(56), Scale(20))

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

    local x, y = frame:GetPos()
    frame:MoveTo(x, y + Scale(14), 0.1, 0, 0.25)
    frame:AlphaTo(0, 0.1, 0, function()
        if IsValid(frame) then
            frame:Remove()
        end
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
