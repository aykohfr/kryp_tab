FreeTablist = FreeTablist or {}
FreeTablist.Config = FreeTablist.Config or {}

local CONFIG = FreeTablist.Config

-- Laissez vide pour utiliser automatiquement le hostname Garry's Mod.
CONFIG.ServerName = ""

-- Texte affiché tout en bas du TAB.
CONFIG.FooterText = "Réalisateur - Kryp Studio ©"

-- Liens optionnels. Un bouton n'est affiché que si son URL est renseignée.
CONFIG.Links = {
    { label = "DISCORD", url = "" },
    { label = "BOUTIQUE", url = "" },
    { label = "SITE", url = "" }
}

-- Couleurs principales de l'interface.
CONFIG.Colors = {
    Background = Color(14, 15, 18, 248),
    Panel = Color(21, 22, 27, 255),
    PanelHover = Color(27, 29, 35, 255),
    Header = Color(18, 19, 23, 255),
    Accent = Color(105, 111, 255, 255),
    AccentSoft = Color(105, 111, 255, 35),
    Text = Color(242, 243, 247, 255),
    Muted = Color(143, 147, 158, 255),
    Divider = Color(43, 45, 54, 255),
    Success = Color(93, 214, 132, 255),
    Danger = Color(235, 92, 92, 255)
}

CONFIG.RefreshInterval = 1
CONFIG.AnimationTime = 0.16
