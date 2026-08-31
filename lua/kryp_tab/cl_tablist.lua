if not CLIENT then return end

KrypTab = KrypTab or {}
local TAB = KrypTab
local CFG = TAB.Config or {}
local COL = CFG.Colors or {}

local STATE = {
    material = nil,
    fetching = false,
    sort = "citoyens"
}

local SORTS = { "citoyens", "profil", "metier", "rang", "temps", "kd", "ping" }

local function C(k, fallback) return COL[k] or fallback end
local function S(v) return math.max(1, math.floor(v * math.Clamp(ScrH() / 1080, 0.72, 1.14))) end
local function A(c, a) return Color(c.r, c.g, c.b, a) end

local function font(name, size, weight)
    surface.CreateFont(name, {
        font = "Roboto",
        size = S(size),
        weight = weight,
        antialias = true,
        extended = true
    })
end

local function buildFonts()
    font("KrypTab.Server", 28, 800)
    font("KrypTab.ServerCount", 14, 500)
    font("KrypTab.Player", 15, 700)
    font("KrypTab.Row", 14, 550)
    font("KrypTab.Small", 12, 500)
    font("KrypTab.Action", 13, 650)
    font("KrypTab.PopupTitle", 22, 800)
    font("KrypTab.PopupText", 13, 500)
end
buildFonts()
hook.Add("OnScreenSizeChanged", "KrypTab.RecreateFonts", buildFonts)

local function serverName()
    if isstring(CFG.ServerName) and string.Trim(CFG.ServerName) ~= "" then return CFG.ServerName end
    return GetHostName()
end

local function playerJob(ply)
    if DarkRP and ply.getDarkRPVar then
        local job = ply:getDarkRPVar("job")
        if isstring(job) and job ~= "" then return job end
    end
    local t = team.GetName(ply:Team())
    if isstring(t) and t ~= "" and t ~= "Unassigned" then return t end
    return "Citoyen"
end

local function playerRank(ply)
    local g = ply:GetUserGroup()
    return isstring(g) and g ~= "" and g or "user"
end

local function playerTime(ply)
    if isfunction(ply.sam_get_play_time) then
        local ok, v = pcall(ply.sam_get_play_time, ply)
        if ok and isnumber(v) then return math.max(0, v) end
    end
    if isfunction(ply.GetUTimeTotalTime) then
        local ok, v = pcall(ply.GetUTimeTotalTime, ply)
        if ok and isnumber(v) then return math.max(0, v) end
    end
    return math.max(0, ply:GetNWInt("playtime", 0))
end

local function fmtTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if h >= 100 then return string.format("%dh", h) end
    return string.format("%02dh %02dm", h, m)
end

local function trimText(fontName, text, maxW)
    text = tostring(text or "")
    surface.SetFont(fontName)
    if surface.GetTextSize(text) <= maxW then return text end
    for i = #text, 1, -1 do
        local candidate = string.sub(text, 1, i) .. "..."
        if surface.GetTextSize(candidate) <= maxW then return candidate end
    end
    return "..."
end

local function pingColor(p)
    p = tonumber(p) or 0
    if p <= 60 then return C("Success", Color(90, 210, 130)) end
    if p <= 110 then return Color(255, 193, 67) end
    if p <= 170 then return Color(255, 147, 57) end
    return C("Danger", Color(236, 76, 76))
end

local function rankColor(r)
    r = string.lower(tostring(r or "user"))
    if r == "superadmin" or r == "owner" or r == "fondateur" then return Color(163, 120, 255) end
    if r == "admin" or r == "moderator" or r == "modérateur" then return Color(120, 174, 255) end
    return C("Text", color_white)
end

local function glow(x, y, w, h, radius, col, n)
    n = n or 3
    for i = 1, n do
        draw.RoundedBox(radius + i, x - i, y - i, w + i * 2, h + i * 2, A(col, math.max(6, 18 - i * 4)))
    end
end

local function ensureMaterial(force)
    local path = CFG.UIImageDataPath or "kryp_tab/l0bpodh.png"
    if not force and STATE.material and not STATE.material:IsError() then return end
    if not force and file.Exists(path, "DATA") and file.Size(path, "DATA") > 1024 then
        STATE.material = Material("../data/" .. path, "smooth noclamp")
        if STATE.material and not STATE.material:IsError() then return end
    end
    if STATE.fetching or not isstring(CFG.UIImageURL) or CFG.UIImageURL == "" then return end
    STATE.fetching = true
    file.CreateDir("kryp_tab")
    http.Fetch(CFG.UIImageURL, function(body, len, _, code)
        STATE.fetching = false
        if code and code >= 400 then return end
        if not body or (len or #body) < 1024 then return end
        file.Write(path, body)
        STATE.material = Material("../data/" .. path, "smooth noclamp")
    end, function() STATE.fetching = false end)
end
ensureMaterial(false)

local function panelRect()
    local aspect = (CFG.UIImageCrop and CFG.UIImageCrop.aspect) or 1.805
    local w = ScrW() * 0.84
    local h = w / aspect
    local maxH = ScrH() * 0.80
    if h > maxH then h = maxH w = h * aspect end
    return (ScrW() - w) * 0.5, (ScrH() - h) * 0.5, w, h
end

local function drawBackplate(x, y, w, h)
    surface.SetDrawColor(0, 0, 0, 135)
    surface.DrawRect(0, 0, ScrW(), ScrH())
    if STATE.material and not STATE.material:IsError() then
        local crop = CFG.UIImageCrop or {}
        surface.SetMaterial(STATE.material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectUV(x, y, w, h, crop.u0 or 0, crop.v0 or 0, crop.u1 or 1, crop.v1 or 1)
    else
        draw.RoundedBox(S(24), x, y, w, h, Color(7, 11, 19, 248))
    end
end

local function hasSAMPermission(perm)
    if not (sam or SAM) then return false end
    local lp = LocalPlayer()
    if not IsValid(lp) or not isstring(perm) or perm == "" then return false end
    if isfunction(lp.HasPermission) then
        local ok, allowed = pcall(lp.HasPermission, lp, perm)
        if ok then return allowed == true end
    end
    return false
end

local function samActions()
    local out = {}
    for _, action in ipairs(CFG.SAMActions or {}) do
        if istable(action) and hasSAMPermission(action.permission or action.command) then out[#out + 1] = action end
    end
    return out
end

local function runSAM(action, target, dur, reason)
    if not IsValid(target) or not hasSAMPermission(action.permission or action.command) then return end
    local cmd, sid = tostring(action.command or ""), target:SteamID()
    if cmd == "" then return end
    if action.duration and action.reason then
        RunConsoleCommand("sam", cmd, sid, tostring(dur or "0"), tostring(reason or ""))
    elseif action.duration then
        RunConsoleCommand("sam", cmd, sid, tostring(dur or "0"))
    elseif action.reason then
        RunConsoleCommand("sam", cmd, sid, tostring(reason or ""))
    else
        RunConsoleCommand("sam", cmd, sid)
    end
end

local function promptSAM(action, target)
    if action.duration then
        return Derma_StringRequest(action.label .. " - " .. target:Nick(), "Durée SAM (ex: 10m, 1h ou 0) :", "0", function(dur)
            if action.reason then
                Derma_StringRequest(action.label .. " - " .. target:Nick(), "Raison :", "", function(reason) runSAM(action, target, dur, reason) end)
            else
                runSAM(action, target, dur)
            end
        end)
    end
    if action.reason then
        return Derma_StringRequest(action.label .. " - " .. target:Nick(), "Raison :", "", function(reason) runSAM(action, target, nil, reason) end)
    end
    runSAM(action, target)
end

local function matchesSearch(ply, q)
    if q == "" then return true end
    q = string.lower(q)
    local values = { ply:Nick(), ply:SteamID(), playerJob(ply), playerRank(ply) }
    for _, v in ipairs(values) do
        if isstring(v) and string.find(string.lower(v), q, 1, true) then return true end
    end
    return false
end

local function sortPlayers(list)
    local mode = STATE.sort or "citoyens"
    table.sort(list, function(a, b)
        if mode == "metier" then
            local aa, bb = string.lower(playerJob(a)), string.lower(playerJob(b))
            return aa == bb and string.lower(a:Nick()) < string.lower(b:Nick()) or aa < bb
        elseif mode == "rang" then
            local aa, bb = string.lower(playerRank(a)), string.lower(playerRank(b))
            return aa == bb and string.lower(a:Nick()) < string.lower(b:Nick()) or aa < bb
        elseif mode == "temps" then
            local aa, bb = playerTime(a), playerTime(b)
            return aa == bb and string.lower(a:Nick()) < string.lower(b:Nick()) or aa > bb
        elseif mode == "kd" then
            local aa, bb = a:Frags() - a:Deaths(), b:Frags() - b:Deaths()
            return aa == bb and string.lower(a:Nick()) < string.lower(b:Nick()) or aa > bb
        elseif mode == "ping" then
            local aa, bb = a:Ping(), b:Ping()
            return aa == bb and string.lower(a:Nick()) < string.lower(b:Nick()) or aa < bb
        end
        if a == LocalPlayer() then return true end
        if b == LocalPlayer() then return false end
        return string.lower(a:Nick()) < string.lower(b:Nick())
    end)
end

local function actionButton(parent, title, desc, accent, fn)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetCursor("hand")
    btn.DoClick = fn
    btn.Title = title
    btn.Desc = desc
    btn.Accent = accent
    btn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        local ac = self.Accent and C("Accent", Color(255, 83, 21)) or Color(77, 94, 122)
        if hover then glow(0, 0, w, h, S(10), ac) end
        draw.RoundedBox(S(10), 0, 0, w, h, hover and Color(18, 25, 38, 250) or Color(13, 18, 28, 245))
        surface.SetDrawColor(hover and ac or C("Divider", Color(57, 69, 89)))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))
        draw.SimpleText(self.Title, "KrypTab.Action", S(14), h * 0.37, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if isstring(self.Desc) and self.Desc ~= "" then
            draw.SimpleText(self.Desc, "KrypTab.Small", S(14), h * 0.70, C("Muted", Color(161, 171, 190)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    return btn
end

function TAB:OpenActions(target)
    if not IsValid(self.Frame) or not IsValid(target) then return end
    if IsValid(self.ActionOverlay) then self.ActionOverlay:Remove() end

    local overlay = vgui.Create("DPanel", self.Frame)
    self.ActionOverlay = overlay
    overlay:SetSize(ScrW(), ScrH())
    overlay:SetPos(0, 0)
    overlay:SetMouseInputEnabled(true)
    overlay.Paint = function(_, w, h) surface.SetDrawColor(0, 0, 0, 95) surface.DrawRect(0, 0, w, h) end
    overlay.OnMousePressed = function() if IsValid(overlay) then overlay:Remove() end end

    local w, h = math.min(S(760), ScrW() * 0.46), math.min(S(560), ScrH() * 0.66)
    local card = vgui.Create("DPanel", overlay)
    card:SetSize(w, h)
    card:Center()
    card:MakePopup()
    card.OnMousePressed = function() end
    card.Paint = function(_, cw, ch)
        glow(0, 0, cw, ch, S(16), C("Accent", Color(255, 83, 21)))
        draw.RoundedBox(S(16), 0, 0, cw, ch, Color(10, 14, 22, 252))
        surface.SetDrawColor(C("Divider", Color(57, 69, 89)))
        surface.DrawOutlinedRect(0, 0, cw, ch, S(1))
        draw.RoundedBox(S(10), S(20), S(92), cw - S(40), S(76), Color(14, 19, 30, 248))
    end

    local close = vgui.Create("DButton", card)
    close:SetText("")
    close:SetCursor("hand")
    close:SetSize(S(44), S(44))
    close:SetPos(w - S(64), S(20))
    close.DoClick = function() if IsValid(overlay) then overlay:Remove() end end
    close.Paint = function(self, bw, bh)
        if self:IsHovered() then glow(0, 0, bw, bh, S(10), C("Accent", Color(255, 83, 21))) end
        draw.RoundedBox(S(10), 0, 0, bw, bh, self:IsHovered() and Color(255, 103, 45) or C("Accent", Color(255, 83, 21)))
        draw.SimpleText("×", "KrypTab.PopupTitle", bw * 0.5, bh * 0.5 - S(1), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local avatar = vgui.Create("AvatarImage", card)
    avatar:SetSize(S(56), S(56))
    avatar:SetPos(S(24), S(24))
    avatar:SetPlayer(target, 64)

    local title = vgui.Create("DLabel", card)
    title:SetFont("KrypTab.PopupTitle")
    title:SetTextColor(color_white)
    title:SetText(trimText("KrypTab.PopupTitle", target:Nick(), w - S(180)))
    title:SetPos(S(96), S(22))
    title:SetSize(w - S(180), S(28))

    local sub = vgui.Create("DLabel", card)
    sub:SetFont("KrypTab.PopupText")
    sub:SetTextColor(C("Muted", Color(161, 171, 190)))
    sub:SetText(target:SteamID() .. "  •  " .. playerJob(target) .. "  •  " .. playerRank(target))
    sub:SetPos(S(96), S(52))
    sub:SetSize(w - S(180), S(24))

    local chips = {
        { "Temps", fmtTime(playerTime(target)) },
        { "Kills", tostring(target:Frags()) },
        { "Morts", tostring(target:Deaths()) },
        { "Ping", tostring(math.max(0, target:Ping())) .. " ms" }
    }
    for i, chip in ipairs(chips) do
        local chipW = (w - S(58)) / 4
        local p = vgui.Create("DPanel", card)
        p:SetPos(S(20) + (i - 1) * (chipW + S(6)), S(102))
        p:SetSize(chipW, S(56))
        p.Paint = function(_, pw, ph)
            draw.RoundedBox(S(9), 0, 0, pw, ph, Color(17, 23, 35, 250))
            surface.SetDrawColor(C("Divider", Color(57, 69, 89)))
            surface.DrawOutlinedRect(0, 0, pw, ph, S(1))
            draw.SimpleText(chip[1], "KrypTab.Small", S(12), ph * 0.34, C("Muted", Color(161, 171, 190)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(chip[2], "KrypTab.Action", S(12), ph * 0.70, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local actions = samActions()
    local canManage = #actions > 0
    local active = canManage and "gestion" or "social"

    local tabs = vgui.Create("DPanel", card)
    tabs:SetPos(S(20), S(172))
    tabs:SetSize(w - S(40), S(42))
    tabs.Paint = function(_, tw, th)
        draw.RoundedBox(S(9), 0, 0, tw, th, Color(13, 18, 28, 245))
        surface.SetDrawColor(C("Divider", Color(57, 69, 89)))
        surface.DrawOutlinedRect(0, 0, tw, th, S(1))
    end

    local list = vgui.Create("DScrollPanel", card)
    list:SetPos(S(20), S(226))
    list:SetSize(w - S(40), h - S(246))
    local vbar = list:GetVBar()
    vbar:SetWide(S(5))
    vbar.Paint = function() end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, bw, bh) draw.RoundedBox(S(4), 0, 0, bw, bh, C("Divider", Color(57, 69, 89))) end

    local function rebuild()
        local canvas = list:GetCanvas()
        canvas:Clear()
        if active == "gestion" and canManage then
            local layout = vgui.Create("DIconLayout", canvas)
            layout:Dock(FILL)
            layout:SetSpaceX(S(10))
            layout:SetSpaceY(S(10))
            local bw = math.floor((list:GetWide() - S(20)) / 2)
            for _, action in ipairs(actions) do
                local b = actionButton(layout, action.label, "Action SAM", true, function() promptSAM(action, target) end)
                b:SetSize(bw, S(58))
            end
        else
            local layout = vgui.Create("DIconLayout", canvas)
            layout:Dock(FILL)
            layout:SetSpaceY(S(10))
            local items = {
                { "Copier le SteamID", target:SteamID(), false, function() SetClipboardText(target:SteamID()) end },
                { "Voir le profil Steam", "Ouvre le profil Steam du joueur", false, function() gui.OpenURL("https://steamcommunity.com/profiles/" .. target:SteamID64()) end },
                { "Ajouter aux contacts", "Ajoute le joueur dans les amis Steam", false, function() gui.OpenURL("steam://friends/add/" .. target:SteamID64()) end }
            }
            local bw = list:GetWide() - S(14)
            for _, item in ipairs(items) do
                local b = actionButton(layout, item[1], item[2], item[3], item[4])
                b:SetSize(bw, S(60))
            end
        end
    end

    local function tabBtn(label, key, x, bw)
        local b = vgui.Create("DButton", tabs)
        b:SetPos(x, S(4))
        b:SetSize(bw, tabs:GetTall() - S(8))
        b:SetText("")
        b:SetCursor("hand")
        b.DoClick = function() active = key rebuild() end
        b.Paint = function(self, pw, ph)
            local on = active == key
            if on then glow(0, 0, pw, ph, S(8), C("Accent", Color(255, 83, 21))) end
            draw.RoundedBox(S(8), 0, 0, pw, ph, on and C("Accent", Color(255, 83, 21)) or self:IsHovered() and Color(20, 28, 41, 255) or Color(16, 22, 33, 255))
            draw.SimpleText(label, "KrypTab.Action", pw * 0.5, ph * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local half = (tabs:GetWide() - S(12)) / 2
    tabBtn("Interactions", "social", S(4), canManage and half or tabs:GetWide() - S(8))
    if canManage then tabBtn("Gestion SAM", "gestion", S(8) + half, half) end
    rebuild()
end

function TAB:BuildPlayers()
    if not IsValid(self.Canvas) then return end
    self.Canvas:Clear()

    local q = IsValid(self.Search) and string.Trim(self.Search:GetValue() or "") or ""
    local list = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and matchesSearch(ply, q) then list[#list + 1] = ply end
    end
    sortPlayers(list)

    if #list == 0 then
        local empty = vgui.Create("DLabel", self.Canvas)
        empty:Dock(TOP)
        empty:SetTall(S(80))
        empty:SetFont("KrypTab.Small")
        empty:SetTextColor(C("Muted", Color(161, 171, 190)))
        empty:SetContentAlignment(5)
        empty:SetText("Aucun joueur ne correspond à la recherche.")
        return
    end

    for _, ply in ipairs(list) do
        local row = vgui.Create("DButton", self.Canvas)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, S(10))
        row:SetTall(S(64))
        row:SetText("")
        row:SetCursor("hand")
        row.DoClick = function() TAB:OpenActions(ply) end

        local avatar = vgui.Create("AvatarImage", row)
        avatar:SetSize(S(42), S(42))
        avatar:SetPos(S(14), S(11))
        avatar:SetPlayer(ply, 64)
        avatar:SetMouseInputEnabled(false)

        row.Paint = function(self, w, h)
            local hover = self:IsHovered()
            if hover then glow(0, 0, w, h, S(8), C("Accent", Color(255, 83, 21))) end
            draw.RoundedBox(S(8), 0, 0, w, h, hover and Color(16, 22, 33, 250) or Color(10, 15, 25, 235))
            surface.SetDrawColor(hover and C("Accent", Color(255, 83, 21)) or A(C("Divider", Color(57, 69, 89)), 120))
            surface.DrawOutlinedRect(0, 0, w, h, S(1))

            local x1, x2, x3, x4, x5, x6 = w * 0.26, w * 0.43, w * 0.595, w * 0.755, w * 0.86, w * 0.955
            local rank = playerRank(ply)
            draw.SimpleText(trimText("KrypTab.Player", ply:Nick(), w * 0.18), "KrypTab.Player", S(68), h * 0.38, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(trimText("KrypTab.Small", ply:SteamID(), w * 0.18), "KrypTab.Small", S(68), h * 0.70, C("Muted", Color(161, 171, 190)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(trimText("KrypTab.Row", playerJob(ply), w * 0.13), "KrypTab.Row", x1, h * 0.5, C("Success", Color(90, 210, 130)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(trimText("KrypTab.Row", rank, w * 0.11), "KrypTab.Row", x2, h * 0.5, rankColor(rank), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(fmtTime(playerTime(ply)), "KrypTab.Row", x3, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(ply:Frags()), "KrypTab.Row", x4, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(ply:Deaths()), "KrypTab.Row", x5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(math.max(0, ply:Ping())) .. " ms", "KrypTab.Row", x6, h * 0.5, pingColor(ply:Ping()), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function TAB:OpenTools()
    if not IsValid(self.Frame) then return end
    if IsValid(self.ToolOverlay) then self.ToolOverlay:Remove() end
    local overlay = vgui.Create("DPanel", self.Frame)
    self.ToolOverlay = overlay
    overlay:SetSize(ScrW(), ScrH())
    overlay:SetPos(0, 0)
    overlay:SetMouseInputEnabled(true)
    overlay.Paint = function(_, w, h) surface.SetDrawColor(0, 0, 0, 70) surface.DrawRect(0, 0, w, h) end
    overlay.OnMousePressed = function() if IsValid(overlay) then overlay:Remove() end end

    local card = vgui.Create("DPanel", overlay)
    card:SetSize(S(360), S(250))
    card:Center()
    card:MakePopup()
    card.OnMousePressed = function() end
    card.Paint = function(_, w, h)
        glow(0, 0, w, h, S(14), C("Accent", Color(255, 83, 21)))
        draw.RoundedBox(S(14), 0, 0, w, h, Color(10, 14, 22, 252))
        surface.SetDrawColor(C("Divider", Color(57, 69, 89)))
        surface.DrawOutlinedRect(0, 0, w, h, S(1))
    end

    local title = vgui.Create("DLabel", card)
    title:SetFont("KrypTab.PopupTitle")
    title:SetTextColor(color_white)
    title:SetText("Paramètres du TAB")
    title:SizeToContents()
    title:SetPos(S(20), S(20))

    local info = vgui.Create("DLabel", card)
    info:SetFont("KrypTab.PopupText")
    info:SetTextColor(C("Muted", Color(161, 171, 190)))
    info:SetWrap(true)
    info:SetAutoStretchVertical(true)
    info:SetText("Rafraîchis la liste ou retélécharge la maquette Imgur si l'UI ne se place pas correctement.")
    info:SetPos(S(20), S(56))
    info:SetSize(card:GetWide() - S(40), S(44))

    local refresh = actionButton(card, "Rafraîchir la liste", "Reconstruit les lignes joueurs", false, function() self:BuildPlayers() end)
    refresh:SetPos(S(20), S(110))
    refresh:SetSize(card:GetWide() - S(40), S(48))

    local reload = actionButton(card, "Recharger l'image UI", "Retélécharge la maquette Imgur", true, function() STATE.material = nil ensureMaterial(true) end)
    reload:SetPos(S(20), S(168))
    reload:SetSize(card:GetWide() - S(40), S(48))
end

function TAB:Open()
    if IsValid(self.Frame) then self.Frame:Remove() end
    ensureMaterial(false)

    local x, y, w, h = panelRect()
    local frame = vgui.Create("DFrame")
    self.Frame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetAlpha(0)
    frame:MakePopup()
    frame.Paint = function()
        drawBackplate(x, y, w, h)
        draw.RoundedBox(S(10), x + w * 0.035, y + h * 0.047, w * 0.25, h * 0.09, Color(8, 12, 20, 95))
        draw.SimpleText(serverName(), "KrypTab.Server", x + w * 0.058, y + h * 0.075, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%d / %d joueurs en ligne", player.GetCount(), game.MaxPlayers()), "KrypTab.ServerCount", x + w * 0.058, y + h * 0.115, C("Muted", Color(161, 171, 190)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    frame.Think = function() if not input.IsKeyDown(KEY_TAB) then TAB:Close() end end
    frame:AlphaTo(255, CFG.AnimationTime or 0.14, 0)

    local barX, barY, barW, barH = x + w * 0.054, y + h * 0.183, w * 0.89, h * 0.07
    local segW = barW / #SORTS
    for i, mode in ipairs(SORTS) do
        local btn = vgui.Create("DButton", frame)
        btn:SetText("")
        btn:SetCursor("hand")
        btn:SetPos(barX + (i - 1) * segW, barY)
        btn:SetSize(segW, barH)
        btn.DoClick = function() STATE.sort = mode self:BuildPlayers() end
        btn.Paint = function(selfBtn, bw, bh)
            if STATE.sort == mode then
                draw.RoundedBox(0, S(10), bh - S(4), bw - S(20), S(3), C("Accent", Color(255, 83, 21)))
            elseif selfBtn:IsHovered() then
                draw.RoundedBox(S(8), S(5), S(4), bw - S(10), bh - S(8), Color(255, 255, 255, 8))
            end
        end
    end

    local search = vgui.Create("DTextEntry", frame)
    self.Search = search
    search:SetPos(x + w * 0.668, y + h * 0.051)
    search:SetSize(w * 0.20, h * 0.062)
    search:SetFont("KrypTab.Row")
    search:SetTextColor(color_white)
    search:SetPlaceholderText("Rechercher...")
    search:SetUpdateOnType(true)
    search.Paint = function(selfEntry, bw, bh)
        draw.RoundedBox(S(8), 0, 0, bw, bh, Color(13, 20, 33, 165))
        if selfEntry:IsHovered() or selfEntry:HasFocus() then glow(0, 0, bw, bh, S(8), C("Accent", Color(255, 83, 21)), 2) end
        selfEntry:DrawTextEntryText(color_white, C("Accent", Color(255, 83, 21)), color_white)
    end
    search.OnValueChange = function() self:BuildPlayers() end

    local gear = vgui.Create("DButton", frame)
    gear:SetText("")
    gear:SetCursor("hand")
    gear:SetPos(x + w * 0.882, y + h * 0.051)
    gear:SetSize(w * 0.043, h * 0.062)
    gear.DoClick = function() self:OpenTools() end
    gear.Paint = function(selfBtn, bw, bh)
        if selfBtn:IsHovered() then glow(0, 0, bw, bh, S(8), C("Accent", Color(255, 83, 21)), 2) draw.RoundedBox(S(8), 0, 0, bw, bh, Color(255, 255, 255, 10)) end
    end

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetCursor("hand")
    close:SetPos(x + w * 0.936, y + h * 0.051)
    close:SetSize(w * 0.046, h * 0.062)
    close.DoClick = function() self:Close() end
    close.Paint = function(selfBtn, bw, bh)
        if selfBtn:IsHovered() then glow(0, 0, bw, bh, S(10), C("Accent", Color(255, 83, 21)), 2) draw.RoundedBox(S(10), 0, 0, bw, bh, Color(255, 255, 255, 12)) end
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(x + w * 0.053, y + h * 0.404)
    scroll:SetSize(w * 0.895, h * 0.51)
    self.Canvas = scroll:GetCanvas()
    local vbar = scroll:GetVBar()
    vbar:SetWide(S(5))
    vbar.Paint = function() end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, bw, bh) draw.RoundedBox(S(4), 0, 0, bw, bh, C("Divider", Color(57, 69, 89))) end

    self:BuildPlayers()
    timer.Remove("KrypTab.Refresh")
    timer.Create("KrypTab.Refresh", CFG.RefreshInterval or 1, 0, function()
        if not IsValid(TAB.Frame) then return timer.Remove("KrypTab.Refresh") end
        TAB:BuildPlayers()
    end)
end

function TAB:Close()
    timer.Remove("KrypTab.Refresh")
    if IsValid(self.ActionOverlay) then self.ActionOverlay:Remove() end
    if IsValid(self.ToolOverlay) then self.ToolOverlay:Remove() end
    if not IsValid(self.Frame) then return end
    local frame = self.Frame
    self.Frame = nil
    frame:AlphaTo(0, 0.08, 0, function() if IsValid(frame) then frame:Remove() end end)
end

hook.Add("ScoreboardShow", "KrypTab.Open", function() TAB:Open() return true end)
hook.Add("ScoreboardHide", "KrypTab.Close", function() TAB:Close() end)
hook.Add("ShutDown", "KrypTab.Cleanup", function() timer.Remove("KrypTab.Refresh") end)
