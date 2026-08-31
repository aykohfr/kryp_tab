KrypTab = KrypTab or {}
KrypTab.Config = KrypTab.Config or {}

local CONFIG = KrypTab.Config

-- Laissez vide pour utiliser automatiquement le hostname Garry's Mod.
CONFIG.ServerName = ""

-- UI officielle du tablist. L'image est téléchargée côté client puis mise en cache.
CONFIG.UIImageURL = "https://i.imgur.com/L0bpoDh.png"
CONFIG.UIImageDataPath = "kryp_tab/L0bpoDh.png"

-- Recadrage de l'image Imgur pour ne conserver que le panneau principal.
-- Ces valeurs correspondent à la maquette L0bpoDh.png.
CONFIG.UIImageCrop = {
    u0 = 0.013,
    v0 = 0.117,
    u1 = 0.968,
    v1 = 0.823,
    aspect = 1.805
}

CONFIG.FooterText = "Réalisateur - Kryp Studio ©"
CONFIG.RefreshInterval = 1
CONFIG.AnimationTime = 0.14

CONFIG.Colors = {
    Background = Color(8, 13, 21, 248),
    Panel = Color(14, 20, 31, 245),
    PanelHover = Color(22, 30, 44, 250),
    Header = Color(23, 31, 45, 245),
    Accent = Color(255, 83, 21, 255),
    AccentSoft = Color(255, 83, 21, 38),
    Text = Color(238, 242, 249, 255),
    Muted = Color(161, 171, 190, 255),
    Divider = Color(57, 69, 89, 180),
    Success = Color(90, 210, 130, 255),
    Danger = Color(236, 76, 76, 255)
}

-- Actions SAM affichées uniquement si le joueur local possède la permission.
CONFIG.SAMActions = {
    { label = "Bring", command = "bring", permission = "bring" },
    { label = "Aller à", command = "goto", permission = "goto" },
    { label = "Freeze", command = "freeze", permission = "freeze", duration = true },
    { label = "Unfreeze", command = "unfreeze", permission = "unfreeze" },
    { label = "Slay", command = "slay", permission = "slay" },
    { label = "Jail", command = "jail", permission = "jail", duration = true },
    { label = "Unjail", command = "unjail", permission = "unjail" },
    { label = "Mute", command = "mute", permission = "mute", duration = true, reason = true },
    { label = "Unmute", command = "unmute", permission = "unmute" },
    { label = "Gag", command = "gag", permission = "gag", duration = true, reason = true },
    { label = "Ungag", command = "ungag", permission = "ungag" },
    { label = "Kick", command = "kick", permission = "kick", reason = true },
    { label = "Ban", command = "ban", permission = "ban", duration = true, reason = true },
    { label = "God", command = "god", permission = "god" },
    { label = "Ungod", command = "ungod", permission = "ungod" },
    { label = "Strip", command = "strip", permission = "strip" }
}
