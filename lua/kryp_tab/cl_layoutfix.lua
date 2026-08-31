if not CLIENT then return end

KrypTab = KrypTab or {}

local function S(value)
    return math.max(1, math.floor(value * math.Clamp(ScrH() / 1080, 0.72, 1.14)))
end

local function GetPanelRect()
    local config = KrypTab.Config or {}
    local aspect = (config.UIImageCrop and config.UIImageCrop.aspect) or 1.805
    local w = ScrW() * 0.84
    local h = w / aspect
    local maxH = ScrH() * 0.80

    if h > maxH then
        h = maxH
        w = h * aspect
    end

    return (ScrW() - w) * 0.5, (ScrH() - h) * 0.5, w, h
end

local lastFrame

hook.Add("Think", "KrypTab.LayoutPolish", function()
    local frame = KrypTab.Frame
    if not IsValid(frame) then
        lastFrame = nil
        return
    end

    if lastFrame == frame then return end
    lastFrame = frame

    local x, y, w, h = GetPanelRect()

    -- Le cadre de recherche est déjà dessiné dans l'image Imgur.
    -- On place donc uniquement une petite zone de saisie sur la partie texte
    -- afin de ne plus superposer un second grand rectangle.
    local search = KrypTab.Search
    if IsValid(search) then
        search:SetPos(x + w * 0.705, y + h * 0.061)
        search:SetSize(w * 0.145, h * 0.044)
        search:SetPlaceholderText("")
        search.Paint = function(self, sw, sh)
            if self:HasFocus() or self:GetValue() ~= "" then
                draw.RoundedBox(S(5), 0, 0, sw, sh, Color(15, 21, 32, 235))
            end

            self:DrawTextEntryText(
                Color(238, 242, 249),
                Color(255, 83, 21),
                Color(238, 242, 249)
            )
        end
    end

    -- Suppression de la ligne orange ajoutée sous l'onglet actif.
    local barY = y + h * 0.183
    local barW = w * 0.89
    local barH = h * 0.07
    local segmentW = barW / 7

    for _, child in ipairs(frame:GetChildren()) do
        if IsValid(child) and child:GetClassName() == "DButton" then
            local _, cy = child:GetPos()
            local cw, ch = child:GetSize()

            if math.abs(cy - barY) <= 3 and math.abs(cw - segmentW) <= 3 and math.abs(ch - barH) <= 3 then
                child.Paint = function(self, bw, bh)
                    if self:IsHovered() then
                        draw.RoundedBox(S(8), S(5), S(4), bw - S(10), bh - S(8), Color(255, 255, 255, 8))
                    end
                end
            end
        end
    end
end)
