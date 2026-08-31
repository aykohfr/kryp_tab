# Kryp Tab

Tablist Garry's Mod moderne ouvrable avec **TAB**, prévu pour fonctionner aussi bien sur DarkRP que sur un gamemode classique.

## Fonctionnalités

- Remplace complètement le scoreboard Garry's Mod par défaut.
- Nom du serveur automatiquement récupéré depuis `hostname` et affiché en haut à gauche.
- Nombre de joueurs en ligne affiché directement sous le nom du serveur.
- Liste dynamique des joueurs avec avatar Steam.
- Métier DarkRP, équipe ou groupe utilisateur en fallback.
- Kills, morts et ping en temps réel.
- Recherche par pseudo, SteamID, groupe ou métier.
- Bouton **PROFIL** : ouvre le profil Steam du joueur.
- Bouton **COPIER** : copie son SteamID.
- Bouton **MUET / RÉACTIVER** : mute/unmute localement le vocal du joueur.
- Animation à l'ouverture et à la fermeture.
- Boutons Discord / Boutique / Site configurables ; ils sont masqués tant qu'aucune URL n'est renseignée.
- Interface responsive pour plusieurs résolutions.

## Installation

Placez le dossier `kryp_tab` dans :

```text
garrysmod/addons/kryp_tab/
```

Puis redémarrez le serveur ou changez de map.

## Configuration

Le fichier principal de configuration est :

```text
lua/kryp_tab/sh_config.lua
```

### Nom du serveur

Par défaut :

```lua
CONFIG.ServerName = ""
```

Une valeur vide utilise automatiquement le `hostname` du serveur. Pour forcer un nom :

```lua
CONFIG.ServerName = "Mon Serveur RP"
```

### Liens

```lua
CONFIG.Links = {
    { label = "DISCORD", url = "https://discord.gg/votre-serveur" },
    { label = "BOUTIQUE", url = "https://votre-boutique.fr" },
    { label = "SITE", url = "https://votre-site.fr" }
}
```

Un lien vide masque automatiquement son bouton.

## Structure

```text
kryp_tab/
├── addon.json
├── README.md
└── lua/
    ├── autorun/
    │   └── kryp_tab.lua
    └── kryp_tab/
        ├── cl_tablist.lua
        └── sh_config.lua
```
