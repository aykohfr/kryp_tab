KrypTab = KrypTab or {}
KrypTab.Config = KrypTab.Config or {}

local CONFIG = KrypTab.Config

-- Laissez vide pour utiliser automatiquement le hostname Garry's Mod.
CONFIG.ServerName = ""
CONFIG.FooterText = "Réalisateur - Kryp Studio ©"
CONFIG.RefreshInterval = 1
CONFIG.AnimationTime = 0.16

-- Dimensions maximales de l'interface.
CONFIG.Width = 1480
CONFIG.Height = 840

-- Thème premium, 100% dessiné en VGUI.
CONFIG.Colors = {
    Backdrop = Color(4, 7, 12, 190),
    Background = Color(8, 12, 19, 252),
    Surface = Color(13, 18, 28, 252),
    Surface2 = Color(17, 23, 35, 252),
    Surface3 = Color(21, 28, 42, 252),
    Border = Color(61, 73, 94, 135),
    BorderStrong = Color(83, 99, 126, 180),
    Accent = Color(255, 91, 36, 255),
    AccentSoft = Color(255, 91, 36, 34),
    AccentGlow = Color(255, 91, 36, 80),
    Text = Color(244, 247, 252, 255),
    Muted = Color(151, 161, 180, 255),
    Faint = Color(101, 112, 132, 255),
    Success = Color(92, 214, 142, 255),
    Warning = Color(255, 188, 72, 255),
    Danger = Color(242, 86, 96, 255),
    Info = Color(105, 164, 255, 255),
    Purple = Color(165, 121, 255, 255)
}

-- Actions SAM affichées uniquement si le joueur local possède la permission.
CONFIG.SAMActions = {
    { label = "Bring", command = "bring", permission = "bring" },
    { label = "Aller à", command = "goto", permission = "goto" },
    { label = "Freeze", command = "freeze", permission = "freeze", duration = true },
    { label = "Unfreeze", command = "unfreeze", permission = "unfreeze" },
    { label = "Slay", command = "slay", permission = "slay", danger = true },
    { label = "Jail", command = "jail", permission = "jail", duration = true },
    { label = "Unjail", command = "unjail", permission = "unjail" },
    { label = "Mute", command = "mute", permission = "mute", duration = true, reason = true },
    { label = "Unmute", command = "unmute", permission = "unmute" },
    { label = "Gag", command = "gag", permission = "gag", duration = true, reason = true },
    { label = "Ungag", command = "ungag", permission = "ungag" },
    { label = "Kick", command = "kick", permission = "kick", reason = true, danger = true },
    { label = "Ban", command = "ban", permission = "ban", duration = true, reason = true, danger = true },
    { label = "God", command = "god", permission = "god" },
    { label = "Ungod", command = "ungod", permission = "ungod" },
    { label = "Strip", command = "strip", permission = "strip", danger = true }
}
