if not CLIENT then return end

KrypTab = KrypTab or {}
local TAB = KrypTab
local CFG = TAB.Config or {}
local COLORS = CFG.Colors or {}

local STATE = {
    Sort = "name",
    OpenedAt = 0
}

local gradientDown = Material("vgui/gradient-d")
local gradientRight = Material("vgui/gradient-r")

local function C(name, fallback)
    return COLORS[name] or fallback
end

local function S(value)
    return math.max(1, math.floor(value * math.Clamp(ScrH() / 1080, 0.72, 1.12)))
end

local function Alpha(col, a)
    return Color(col.r, col.g, col.b, a)
end

local function LerpColor(frac, a, b)
    return Color(
        Lerp(frac, a.r, b.r),
        Lerp(frac, a.g, b.g),
        Lerp(frac, a.b, b.b),
        Lerp(frac, a.a or 255, b.a or 255)
    )
end

local function MakeFont(name, size, weight)
    surface.CreateFont(name, {
        font = "Roboto",
        size = S(size),
        weight = weight,
        antialias = true,
        extended = true
    })
end

local function BuildFonts()
    MakeFont("KrypTab.Brand", 11, 800)
    MakeFont("KrypTab.Server", 28, 800)
    MakeFont("KrypTab.Subtitle", 13, 500)
    MakeFont("KrypTab.Stat", 21, 800)
    MakeFont("KrypTab.StatLabel", 11, 700)
    MakeFont("KrypTab.Column", 11, 800)
    MakeFont("KrypTab.Player", 15, 700)
    MakeFont("KrypTab.Row", 13, 550)
    MakeFont("KrypTab.Small", 11, 500)
    MakeFont("KrypTab.Button", 12, 700)
    MakeFont("KrypTab.ModalTitle", 22, 800)
    MakeFont("KrypTab.ModalText", 13, 550)
end

BuildFonts()
hook.Add("OnScreenSizeChanged", "KrypTab.RebuildFonts", BuildFonts)

local function ServerName()
    if isstring(CFG.ServerName) and string.Trim(CFG.ServerName) ~= "" then
        return CFG.ServerName
    end
    return GetHostName()
end

local function PlayerJob(ply)
    if DarkRP and ply.getDarkRPVar then
        local job = ply:getDarkRPVar("job")
        if isstring(job) and job ~= "" then return job end
    end

    local teamName = team.GetName(ply:Team())
    if isstring(teamName) and teamName ~= "" and teamName ~= "Unassigned" then
        return teamName
    end

    return "Citoyen"
end

local function PlayerRank(ply)
    local group = ply:GetUserGroup()
    return isstring(group) and group ~= "" and group or "user"
end

local function PlayerTime(ply)
    if isfunction(ply.sam_get_play_time) then
        local ok, result = pcall(ply.sam_get_play_time, ply)
        if ok and isnumber(result) then return math.max(0, result) end
    end

    if isfunction(ply.GetUTimeTotalTime) then
        local ok, result = pcall(ply.GetUTimeTotalTime, ply)
        if ok and isnumber(result) then return math.max(0, result) end
    end

    return math.max(0, ply:GetNWInt("playtime", 0))
end

local function FormatTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours >= 100 then return string.format("%dh", hours) end
    return string.format("%02dh %02dm", hours, minutes)
end

local function TrimText(font, text, maxWidth)
    text = tostring(text or "")
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxWidth then return text end

    for i = #text, 1, -1 do
        local candidate = string.sub(text, 1, i) .. "..."
        if surface.GetTextSize(candidate) <= maxWidth then return candidate end
    end
    return "..."
end

local function RankColor(rank)
    rank = string.lower(tostring(rank or "user"))
    if rank == "superadmin" or rank == "owner" or rank == "fondateur" then
        return C("Purple", Color(165, 121, 255))
    end
    if rank == "admin" or rank == "moderator" or rank == "modérateur" then
        return C("Info", Color(105, 164, 255))
    end
    return C("Text", color_white)
end

local function PingColor(ping)
    ping = tonumber(ping) or 0
    if ping <= 60 then return C("Success", Color(92, 214, 142)) end
    if ping <= 110 then return C("Warning", Color(255, 188, 72)) end
    if ping <= 170 then return Color(255, 139, 75) end
    return C("Danger", Color(242, 86, 96))
end

local function AveragePing()
    local players = player.GetAll()
    if #players == 0 then return 0 end
    local total = 0
    for _, ply in ipairs(players) do total = total + math.max(0, ply:Ping()) end
    return math.floor(total / #players)
end

local function StaffOnline()
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        local group = string.lower(PlayerRank(ply))
        if group ~= "user" and group ~= "default" and group ~= "player" then count = count + 1 end
    end
    return count
end

local function DrawGlow(x, y, w, h, radius, col, alpha)
    alpha = alpha or 22
    for i = 4, 1, -1 do
        draw.RoundedBox(radius + i * 2, x - i * 2, y - i * 2, w + i * 4, h + i * 4, Alpha(col, math.max(3, alpha - i * 4)))
    end
end

local function DrawShadow(x, y, w, h, radius)
    for i = 5, 1, -1 do
        draw.RoundedBox(radius + i * 2, x - i * 2, y + i * 2, w + i * 4, h + i * 4, Color(0, 0, 0, 18 - i))
    end
end

local function HasSAMPermission(permission)
    if not (sam or SAM) then return false end
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
    for _, action in ipairs(CFG.SAMActions or {}) do
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
    if action.duration then
        Derma_StringRequest(
            action.label .. " • " .. target:Nick(),
            "Durée SAM (ex: 10m, 1h, 0) :",
            "0",
            function(duration)
                if action.reason then
                    Derma_StringRequest(
                        action.label .. " • " .. target:Nick(),
                        "Raison :",
                        "",
                        function(reason) RunSAMAction(action, target, duration, reason) end
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
            action.label .. " • " .. target:Nick(),
            "Raison :",
            "",
            function(reason) RunSAMAction(action, target, nil, reason) end
        )
        return
    end

    RunSAMAction(action, target)
end

local function MatchPlayer(ply, query)
    if query == "" then return true end
    query = string.lower(query)
    local values = { ply:Nick(), ply:SteamID(), PlayerJob(ply), PlayerRank(ply) }
    for _, value in ipairs(values) do
        if isstring(value) and string.find(string.lower(value), query, 1, true) then return true end
    end
    return false
end

local function SortPlayers(players)
    local mode = STATE.Sort
    table.sort(players, function(a, b)
        if mode == "job" then
            local av, bv = string.lower(PlayerJob(a)), string.lower(PlayerJob(b))
            if av == bv then return string.lower(a:Nick()) < string.lower(b:Nick()) end
            return av < bv
        elseif mode == "rank" then
            local av, bv = string.lower(PlayerRank(a)), string.lower(PlayerRank(b))
            if av == bv then return string.lower(a:Nick()) < string.lower(b:Nick()) end
            return av < bv
        elseif mode == "time" then
            local av, bv = PlayerTime(a), PlayerTime(b)
            if av == bv then return string.lower(a:Nick()) < string.lower(b:Nick()) end
            return av > bv
        elseif mode == "kd" then
            local av, bv = a:Frags() - a:Deaths(), b:Frags() - b:Deaths()
            if av == bv then return string.lower(a:Nick()) < string.lower(b:Nick()) end
            return av > bv
        elseif mode == "ping" then
            local av, bv = a:Ping(), b:Ping()
            if av == bv then return string.lower(a:Nick()) < string.lower(b:Nick()) end
            return av < bv
        end

        if a == LocalPlayer() then return true end
        if b == LocalPlayer() then return false end
        return string.lower(a:Nick()) < string.lower(b:Nick())
    end)
end

local function MakePremiumButton(parent, label, icon, accent, callback)
    local button = vgui.Create("DButton", parent)
    button:SetText("")
    button:SetCursor("hand")
    button.Hover = 0
    button.DoClick = callback
    button.Paint = function(self, w, h)
        self.Hover = Lerp(FrameTime() * 12, self.Hover, self:IsHovered() and 1 or 0)
        local base = LerpColor(self.Hover, C("Surface2", Color(17, 23, 35)), C("Surface3", Color(21, 28, 42)))
        draw.RoundedBox(S(9), 0, 0, w, h, base)
        surface.SetDrawColor(LerpColor(self.Hover, C("Border", Color(61, 73, 94)), accent or C("Accent", Color(255, 91, 36))))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))
        if self.Hover > 0.05 then DrawGlow(0, 0, w, h, S(9), accent or C("Accent", Color(255, 91, 36)), 15 * self.Hover) end

        if icon and icon ~= "" then
            draw.SimpleText(icon, "KrypTab.Button", S(14), h / 2, accent or C("Accent", Color(255, 91, 36)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(label, "KrypTab.Button", S(38), h / 2, C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(label, "KrypTab.Button", w / 2, h / 2, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    return button
end

function TAB:OpenPlayerActions(target)
    if not IsValid(target) or not IsValid(self.Frame) then return end
    if IsValid(self.ActionOverlay) then self.ActionOverlay:Remove() end

    local overlay = vgui.Create("DPanel", self.Frame)
    self.ActionOverlay = overlay
    overlay:SetSize(ScrW(), ScrH())
    overlay:SetPos(0, 0)
    overlay:SetMouseInputEnabled(true)
    overlay.Paint = function(_, w, h)
        surface.SetDrawColor(0, 0, 0, 125)
        surface.DrawRect(0, 0, w, h)
    end
    overlay.OnMousePressed = function() if IsValid(overlay) then overlay:Remove() end end

    local modalW = math.min(S(760), ScrW() * 0.50)
    local modalH = math.min(S(570), ScrH() * 0.70)
    local modal = vgui.Create("DPanel", overlay)
    modal:SetSize(modalW, modalH)
    modal:Center()
    modal:SetAlpha(0)
    modal:AlphaTo(255, 0.14, 0)
    modal:MakePopup()
    modal.OnMousePressed = function() end
    modal.Paint = function(_, w, h)
        DrawShadow(0, 0, w, h, S(16))
        DrawGlow(0, 0, w, h, S(16), C("Accent", Color(255, 91, 36)), 14)
        draw.RoundedBox(S(16), 0, 0, w, h, C("Background", Color(8, 12, 19)))
        surface.SetDrawColor(C("BorderStrong", Color(83, 99, 126)))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))

        surface.SetMaterial(gradientRight)
        surface.SetDrawColor(255, 255, 255, 16)
        surface.DrawTexturedRect(0, 0, w, S(110))

        draw.RoundedBox(S(10), S(18), S(92), w - S(36), S(76), C("Surface", Color(13, 18, 28)))
    end

    local avatar = vgui.Create("AvatarImage", modal)
    avatar:SetSize(S(58), S(58))
    avatar:SetPos(S(22), S(20))
    avatar:SetPlayer(target, 64)

    local title = vgui.Create("DLabel", modal)
    title:SetFont("KrypTab.ModalTitle")
    title:SetTextColor(C("Text", color_white))
    title:SetText(TrimText("KrypTab.ModalTitle", target:Nick(), modalW - S(190)))
    title:SetPos(S(96), S(20))
    title:SetSize(modalW - S(190), S(30))

    local subtitle = vgui.Create("DLabel", modal)
    subtitle:SetFont("KrypTab.ModalText")
    subtitle:SetTextColor(C("Muted", Color(151, 161, 180)))
    subtitle:SetText(target:SteamID() .. "  •  " .. PlayerJob(target) .. "  •  " .. PlayerRank(target))
    subtitle:SetPos(S(97), S(52))
    subtitle:SetSize(modalW - S(200), S(22))

    local close = MakePremiumButton(modal, "×", nil, C("Danger", Color(242, 86, 96)), function()
        if IsValid(overlay) then overlay:Remove() end
    end)
    close:SetSize(S(44), S(44))
    close:SetPos(modalW - S(62), S(20))

    local chips = {
        { "TEMPS", FormatTime(PlayerTime(target)), C("Info", Color(105, 164, 255)) },
        { "KILLS", tostring(target:Frags()), C("Success", Color(92, 214, 142)) },
        { "MORTS", tostring(target:Deaths()), C("Danger", Color(242, 86, 96)) },
        { "PING", tostring(math.max(0, target:Ping())) .. " ms", PingColor(target:Ping()) }
    }

    for i, chip in ipairs(chips) do
        local chipW = (modalW - S(54)) / 4
        local panel = vgui.Create("DPanel", modal)
        panel:SetPos(S(18) + (i - 1) * (chipW + S(6)), S(102))
        panel:SetSize(chipW, S(56))
        panel.Paint = function(_, w, h)
            draw.RoundedBox(S(9), 0, 0, w, h, C("Surface2", Color(17, 23, 35)))
            surface.SetDrawColor(C("Border", Color(61, 73, 94)))
            surface.DrawOutlinedRect(0, 0, w, h, S(1))
            draw.SimpleText(chip[1], "KrypTab.StatLabel", S(12), S(17), C("Muted", Color(151, 161, 180)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(chip[2], "KrypTab.Button", S(12), S(39), chip[3], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local samActions = GetSAMActions()
    local canManage = #samActions > 0
    local activeTab = canManage and "admin" or "social"

    local tabBar = vgui.Create("DPanel", modal)
    tabBar:SetPos(S(18), S(180))
    tabBar:SetSize(modalW - S(36), S(44))
    tabBar.Paint = function(_, w, h)
        draw.RoundedBox(S(10), 0, 0, w, h, C("Surface", Color(13, 18, 28)))
    end

    local content = vgui.Create("DScrollPanel", modal)
    content:SetPos(S(18), S(238))
    content:SetSize(modalW - S(36), modalH - S(256))
    local vbar = content:GetVBar()
    vbar:SetWide(S(4))
    vbar.Paint = function() end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(S(4), 0, 0, w, h, C("BorderStrong", Color(83, 99, 126))) end

    local function RebuildContent()
        local canvas = content:GetCanvas()
        canvas:Clear()

        if activeTab == "admin" and canManage then
            local grid = vgui.Create("DIconLayout", canvas)
            grid:Dock(FILL)
            grid:SetSpaceX(S(10))
            grid:SetSpaceY(S(10))
            local cellW = math.floor((content:GetWide() - S(20)) / 2)

            for _, action in ipairs(samActions) do
                local accent = action.danger and C("Danger", Color(242, 86, 96)) or C("Accent", Color(255, 91, 36))
                local button = MakePremiumButton(grid, action.label, action.danger and "!" or ">", accent, function()
                    PromptSAMAction(action, target)
                end)
                button:SetSize(cellW, S(54))
            end
        else
            local list = vgui.Create("DIconLayout", canvas)
            list:Dock(FILL)
            list:SetSpaceY(S(10))
            local width = content:GetWide() - S(12)

            local actions = {
                { "Copier le SteamID", "#", C("Info", Color(105, 164, 255)), function()
                    if not IsValid(target) then return end
                    SetClipboardText(target:SteamID())
                    notification.AddLegacy("SteamID copié : " .. target:SteamID(), NOTIFY_GENERIC, 2)
                end },
                { "Voir le profil Steam", "↗", C("Success", Color(92, 214, 142)), function()
                    if not IsValid(target) then return end
                    gui.OpenURL("https://steamcommunity.com/profiles/" .. target:SteamID64())
                end },
                { "Ajouter aux contacts", "+", C("Purple", Color(165, 121, 255)), function()
                    if not IsValid(target) then return end
                    gui.OpenURL("steam://friends/add/" .. target:SteamID64())
                end }
            }

            for _, action in ipairs(actions) do
                local button = MakePremiumButton(list, action[1], action[2], action[3], action[4])
                button:SetSize(width, S(56))
            end
        end
    end

    local function MakeTab(label, key, x, width)
        local button = vgui.Create("DButton", tabBar)
        button:SetPos(x, S(4))
        button:SetSize(width, tabBar:GetTall() - S(8))
        button:SetText("")
        button:SetCursor("hand")
        button.Hover = 0
        button.DoClick = function()
            activeTab = key
            RebuildContent()
        end
        button.Paint = function(self, w, h)
            self.Hover = Lerp(FrameTime() * 12, self.Hover, self:IsHovered() and 1 or 0)
            local active = activeTab == key
            draw.RoundedBox(S(8), 0, 0, w, h, active and C("Surface3", Color(21, 28, 42)) or Alpha(C("Surface2", Color(17, 23, 35)), 70 + 70 * self.Hover))
            if active then
                surface.SetDrawColor(C("Accent", Color(255, 91, 36)))
                surface.DrawRect(S(12), h - S(2), w - S(24), S(2))
            end
            draw.SimpleText(label, "KrypTab.Button", w / 2, h / 2, active and C("Text", color_white) or C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    if canManage then
        local half = (tabBar:GetWide() - S(12)) / 2
        MakeTab("Interactions", "social", S(4), half)
        MakeTab("Administration SAM", "admin", S(8) + half, half)
    else
        MakeTab("Interactions", "social", S(4), tabBar:GetWide() - S(8))
    end

    RebuildContent()
end

function TAB:BuildPlayerList()
    if not IsValid(self.PlayerCanvas) then return end
    self.PlayerCanvas:Clear()

    local query = IsValid(self.SearchEntry) and string.Trim(self.SearchEntry:GetValue() or "") or ""
    local players = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and MatchPlayer(ply, query) then players[#players + 1] = ply end
    end
    SortPlayers(players)

    if #players == 0 then
        local empty = vgui.Create("DPanel", self.PlayerCanvas)
        empty:Dock(TOP)
        empty:SetTall(S(120))
        empty.Paint = function(_, w, h)
            draw.SimpleText("Aucun joueur trouvé", "KrypTab.Player", w / 2, h / 2 - S(8), C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Essayez un pseudo, SteamID, métier ou rang.", "KrypTab.Small", w / 2, h / 2 + S(14), C("Faint", Color(101, 112, 132)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for _, ply in ipairs(players) do
        local row = vgui.Create("DButton", self.PlayerCanvas)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, S(8))
        row:SetTall(S(68))
        row:SetText("")
        row:SetCursor("hand")
        row.Hover = 0
        row.DoClick = function() TAB:OpenPlayerActions(ply) end

        local avatar = vgui.Create("AvatarImage", row)
        avatar:SetSize(S(42), S(42))
        avatar:SetPos(S(14), S(13))
        avatar:SetPlayer(ply, 64)
        avatar:SetMouseInputEnabled(false)

        row.Paint = function(self, w, h)
            self.Hover = Lerp(FrameTime() * 12, self.Hover, self:IsHovered() and 1 or 0)
            local surfaceCol = LerpColor(self.Hover, C("Surface", Color(13, 18, 28)), C("Surface2", Color(17, 23, 35)))
            if self.Hover > 0.04 then DrawGlow(0, 0, w, h, S(10), C("Accent", Color(255, 91, 36)), 10 * self.Hover) end
            draw.RoundedBox(S(10), 0, 0, w, h, surfaceCol)
            surface.SetDrawColor(LerpColor(self.Hover, C("Border", Color(61, 73, 94)), C("BorderStrong", Color(83, 99, 126))))
            surface.DrawOutlinedRect(0, 0, w, h, S(1))

            local rank = PlayerRank(ply)
            local job = PlayerJob(ply)
            local ping = math.max(0, ply:Ping())

            local xJob = w * 0.31
            local xRank = w * 0.47
            local xTime = w * 0.63
            local xKD = w * 0.78
            local xPing = w * 0.92

            draw.SimpleText(TrimText("KrypTab.Player", ply:Nick(), w * 0.19), "KrypTab.Player", S(68), S(25), C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(TrimText("KrypTab.Small", ply:SteamID(), w * 0.19), "KrypTab.Small", S(68), S(46), C("Muted", Color(151, 161, 180)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            draw.SimpleText(TrimText("KrypTab.Row", job, w * 0.12), "KrypTab.Row", xJob, h / 2, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(TrimText("KrypTab.Row", rank, w * 0.10), "KrypTab.Row", xRank, h / 2, RankColor(rank), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(FormatTime(PlayerTime(ply)), "KrypTab.Row", xTime, h / 2, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format("%d / %d", ply:Frags(), ply:Deaths()), "KrypTab.Row", xKD, h / 2, C("Text", color_white), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            draw.RoundedBox(S(3), xPing - S(31), h / 2 - S(3), S(6), S(6), PingColor(ping))
            draw.SimpleText(ping .. " ms", "KrypTab.Row", xPing, h / 2, PingColor(ping), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function TAB:Open()
    if IsValid(self.Frame) then self.Frame:Remove() end

    local frameW = math.min(S(CFG.Width or 1480), ScrW() * 0.88)
    local frameH = math.min(S(CFG.Height or 840), ScrH() * 0.84)
    local frameX = (ScrW() - frameW) / 2
    local frameY = (ScrH() - frameH) / 2

    local frame = vgui.Create("DFrame")
    self.Frame = frame
    STATE.OpenedAt = CurTime()
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetSizable(false)
    frame:SetAlpha(0)
    frame:MakePopup()
    frame:AlphaTo(255, CFG.AnimationTime or 0.16, 0)
    frame.Think = function()
        if not input.IsKeyDown(KEY_TAB) then TAB:Close() end
    end
    frame.Paint = function(_, w, h)
        surface.SetDrawColor(C("Backdrop", Color(4, 7, 12, 190)))
        surface.DrawRect(0, 0, w, h)

        surface.SetMaterial(gradientDown)
        surface.SetDrawColor(24, 36, 54, 40)
        surface.DrawTexturedRect(0, 0, w, h * 0.75)

        DrawShadow(frameX, frameY, frameW, frameH, S(18))
        DrawGlow(frameX, frameY, frameW, frameH, S(18), C("Accent", Color(255, 91, 36)), 10)
        draw.RoundedBox(S(18), frameX, frameY, frameW, frameH, C("Background", Color(8, 12, 19)))
        surface.SetDrawColor(C("BorderStrong", Color(83, 99, 126)))
        surface.DrawOutlinedRect(frameX, frameY, frameW, frameH, S(1))

        surface.SetMaterial(gradientRight)
        surface.SetDrawColor(255, 255, 255, 11)
        surface.DrawTexturedRect(frameX, frameY, frameW, S(130))

        draw.RoundedBoxEx(S(18), frameX, frameY, frameW, S(4), C("Accent", Color(255, 91, 36)), true, true, false, false)

        draw.SimpleText("KRYP TAB", "KrypTab.Brand", frameX + S(28), frameY + S(28), C("Accent", Color(255, 91, 36)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(ServerName(), "KrypTab.Server", frameX + S(28), frameY + S(58), C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%d / %d joueurs en ligne", player.GetCount(), game.MaxPlayers()), "KrypTab.Subtitle", frameX + S(29), frameY + S(86), C("Muted", Color(151, 161, 180)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText(CFG.FooterText or "", "KrypTab.Small", frameX + frameW / 2, frameY + frameH - S(17), C("Faint", Color(101, 112, 132)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local contentX = frameX + S(28)
    local contentW = frameW - S(56)

    local search = vgui.Create("DTextEntry", frame)
    self.SearchEntry = search
    search:SetPos(frameX + frameW - S(390), frameY + S(28))
    search:SetSize(S(300), S(44))
    search:SetFont("KrypTab.Row")
    search:SetTextColor(C("Text", color_white))
    search:SetPlaceholderText("Rechercher un joueur...")
    search:SetUpdateOnType(true)
    search.Paint = function(self, w, h)
        local focused = self:HasFocus() or self:IsHovered()
        if focused then DrawGlow(0, 0, w, h, S(10), C("Accent", Color(255, 91, 36)), 10) end
        draw.RoundedBox(S(10), 0, 0, w, h, C("Surface", Color(13, 18, 28)))
        surface.SetDrawColor(focused and C("BorderStrong", Color(83, 99, 126)) or C("Border", Color(61, 73, 94)))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))
        self:DrawTextEntryText(C("Text", color_white), C("Accent", Color(255, 91, 36)), C("Muted", Color(151, 161, 180)))
    end
    search.OnValueChange = function() TAB:BuildPlayerList() end

    local close = MakePremiumButton(frame, "×", nil, C("Danger", Color(242, 86, 96)), function() TAB:Close() end)
    close:SetSize(S(44), S(44))
    close:SetPos(frameX + frameW - S(72), frameY + S(28))

    local cardsY = frameY + S(116)
    local cardGap = S(10)
    local cardW = (contentW - cardGap * 2) / 3
    local cards = {
        { "JOUEURS", function() return tostring(player.GetCount()) end, C("Accent", Color(255, 91, 36)) },
        { "PING MOYEN", function() return AveragePing() .. " ms" end, C("Info", Color(105, 164, 255)) },
        { "STAFF EN LIGNE", function() return tostring(StaffOnline()) end, C("Purple", Color(165, 121, 255)) }
    }

    for i, info in ipairs(cards) do
        local card = vgui.Create("DPanel", frame)
        card:SetPos(contentX + (i - 1) * (cardW + cardGap), cardsY)
        card:SetSize(cardW, S(72))
        card.Paint = function(_, w, h)
            draw.RoundedBox(S(11), 0, 0, w, h, C("Surface", Color(13, 18, 28)))
            surface.SetDrawColor(C("Border", Color(61, 73, 94)))
            surface.DrawOutlinedRect(0, 0, w, h, S(1))
            draw.RoundedBox(S(3), S(14), S(15), S(6), h - S(30), info[3])
            draw.SimpleText(info[1], "KrypTab.StatLabel", S(32), S(23), C("Muted", Color(151, 161, 180)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(info[2](), "KrypTab.Stat", S(32), S(48), C("Text", color_white), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local filtersY = cardsY + S(88)
    local filters = {
        { "Joueurs", "name" },
        { "Métier", "job" },
        { "Rang", "rank" },
        { "Temps de jeu", "time" },
        { "K/D", "kd" },
        { "Ping", "ping" }
    }

    local filterX = contentX
    for _, filter in ipairs(filters) do
        surface.SetFont("KrypTab.Button")
        local textW = surface.GetTextSize(filter[1])
        local width = textW + S(28)
        local button = vgui.Create("DButton", frame)
        button:SetPos(filterX, filtersY)
        button:SetSize(width, S(36))
        button:SetText("")
        button:SetCursor("hand")
        button.Hover = 0
        button.DoClick = function()
            STATE.Sort = filter[2]
            TAB:BuildPlayerList()
        end
        button.Paint = function(self, w, h)
            self.Hover = Lerp(FrameTime() * 12, self.Hover, self:IsHovered() and 1 or 0)
            local active = STATE.Sort == filter[2]
            draw.RoundedBox(S(9), 0, 0, w, h, active and C("AccentSoft", Color(255, 91, 36, 34)) or Alpha(C("Surface", Color(13, 18, 28)), 160 + 60 * self.Hover))
            surface.SetDrawColor(active and C("Accent", Color(255, 91, 36)) or C("Border", Color(61, 73, 94)))
            surface.DrawOutlinedRect(0, 0, w, h, S(1))
            draw.SimpleText(filter[1], "KrypTab.Button", w / 2, h / 2, active and C("Accent", Color(255, 91, 36)) or C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        filterX = filterX + width + S(8)
    end

    local headerY = filtersY + S(50)
    local header = vgui.Create("DPanel", frame)
    header:SetPos(contentX, headerY)
    header:SetSize(contentW, S(42))
    header.Paint = function(_, w, h)
        draw.RoundedBox(S(9), 0, 0, w, h, C("Surface2", Color(17, 23, 35)))
        surface.SetDrawColor(C("Border", Color(61, 73, 94)))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))
        draw.SimpleText("JOUEUR", "KrypTab.Column", S(18), h / 2, C("Muted", Color(151, 161, 180)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("MÉTIER", "KrypTab.Column", w * 0.31, h / 2, C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("RANG", "KrypTab.Column", w * 0.47, h / 2, C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("TEMPS DE JEU", "KrypTab.Column", w * 0.63, h / 2, C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("K / D", "KrypTab.Column", w * 0.78, h / 2, C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("PING", "KrypTab.Column", w * 0.92, h / 2, C("Muted", Color(151, 161, 180)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(contentX, headerY + S(52))
    scroll:SetSize(contentW, frameY + frameH - S(42) - (headerY + S(52)))
    self.PlayerCanvas = scroll:GetCanvas()
    local vbar = scroll:GetVBar()
    vbar:SetWide(S(4))
    vbar.Paint = function() end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(S(4), 0, 0, w, h, C("BorderStrong", Color(83, 99, 126))) end

    self:BuildPlayerList()

    timer.Remove("KrypTab.Refresh")
    timer.Create("KrypTab.Refresh", CFG.RefreshInterval or 1, 0, function()
        if not IsValid(TAB.Frame) then
            timer.Remove("KrypTab.Refresh")
            return
        end
        TAB:BuildPlayerList()
    end)
end

function TAB:Close()
    timer.Remove("KrypTab.Refresh")
    if IsValid(self.ActionOverlay) then self.ActionOverlay:Remove() end
    if not IsValid(self.Frame) then return end

    local frame = self.Frame
    self.Frame = nil
    frame:AlphaTo(0, 0.08, 0, function()
        if IsValid(frame) then frame:Remove() end
    end)
end

hook.Add("ScoreboardShow", "KrypTab.Open", function()
    TAB:Open()
    return true
end)

hook.Add("ScoreboardHide", "KrypTab.Close", function()
    TAB:Close()
end)

hook.Add("ShutDown", "KrypTab.Cleanup", function()
    timer.Remove("KrypTab.Refresh")
end)
