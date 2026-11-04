# Arborescence de développement — Death Note

Guilde : **Le Syndicat Rouge**. Client unique : **WoW Forever**.
État : architecture prévue le 4 novembre 2026 ; les fichiers Lua, TOC et Python ci-dessous ne sont pas encore implémentés. Les maquettes existantes restent dans `docs/plans/death-note/assets/`.

## Arborescence prévue

```text
Addon Death Note/
├── README.md
├── .gitignore
│
├── addon/
│   └── SyndicatRouge/                  # Seul dossier à installer dans WoW
│       ├── SyndicatRouge.toc           # Métadonnées, sauvegarde, ordre des fichiers
│       ├── Init.lua                    # Namespace de l'addon
│       ├── Config.lua                  # Identité, réglages par défaut, barèmes
│       ├── Core.lua                    # Initialisation et branchement des modules
│       ├── Forever/
│       │   ├── Client.lua              # Build et capacités du client Forever
│       │   └── Combat.lua              # Observation autorisée des combats
│       ├── Data/
│       │   ├── Store.lua               # SavedVariables, schéma, migrations
│       │   └── Validation.lua          # Contrôle des données locales et reçues
│       ├── Features/
│       │   ├── Incidents.lua           # Victime, ennemi, lieu, heure, état
│       │   ├── Wanted.lua              # Ennemis recherchés et prime de recherche
│       │   ├── Vengeance.lua           # Clôture des incidents, attribution
│       │   ├── Reputation.lua          # Récompenses et classement des membres
│       │   ├── Notifications.lua       # Alertes, lecture et remerciement volontaire
│       │   └── Nameplates.lua          # Marqueur local au-dessus des noms
│       ├── Sync/
│       │   ├── Protocol.lua            # Format versionné et limites des messages
│       │   └── Guild.lua               # Partage, doublons et rattrapage
│       ├── UI/
│       │   ├── Theme.lua               # Couleurs, polices et références aux textures
│       │   ├── Widgets.lua             # Portraits, tampons et lignes réutilisables
│       │   ├── Window.lua              # Fenêtre, onglets et navigation
│       │   ├── WantedView.lua          # Liste, dossier et carte du dernier meurtre
│       │   ├── AvengersView.lua        # Classement et fiche d'un vengeur
│       │   ├── JournalView.lua         # Chronologie et filtres
│       │   └── NotificationsView.lua   # Alertes et préférences
│       ├── Export/
│       │   └── DiscordOutbox.lua       # Événements exportables, aucun secret Discord
│       └── Media/
│           ├── Textures/               # Parchemin, cuir, cadres et tampons
│           ├── Icons/                  # Emblème de guilde, classe et race
│           └── Fonts/                  # Polices utilisables et leurs licences
│
├── bridge/                             # Programme optionnel extérieur au jeu
│   ├── README.md
│   ├── config.example.json             # Exemple sans secret
│   └── syndicat_rouge/
│       ├── __main__.py                 # Lancement du relais
│       ├── export_reader.py            # Lecture sûre de l'export validé
│       ├── delivery.py                 # File, état d'envoi, déduplication, reprises
│       └── discord.py                  # Publication webhook et limites Discord
│
├── tests/
│   ├── lua/                            # Incidents, vengeance, réputation et sync
│   ├── bridge/                         # Export, doublons, erreurs et reprise réseau
│   └── fixtures/                       # Données fictives, jamais chargées en production
│
├── tools/
│   ├── check_package.py                # Vérifie TOC, fichiers et contenu distribuable
│   └── package.py                      # Produit les archives de livraison
├── docs/
│   ├── architecture.md                 # Ce document
│   ├── api-evidence/                   # Preuves de source, builds, restrictions
│   ├── testing/                        # Procédures et résultats, dont Forever réel
│   └── plans/death-note/               # Besoins, suivi, maquettes et choix visuels
└── dist/                               # Archives générées, hors gestion de sources
```

## Frontières et responsabilités

**Addon WoW.** Le dossier technique `SyndicatRouge` est stable et dédié à la guilde ; le titre affiché reste DEATH NOTE. Un membre n'installe que ce dossier dans `Interface/AddOns/`. Aucun fichier Python, fixture ou secret ne doit y être distribué.

**Cible unique.** `Forever/` isole les appels propres à Forever ; aucun adaptateur Retail ou Classic n'est prévu. Les vues et les règles métier ne devinent pas les API à partir de leur existence. Un build inconnu ou une capacité inaccessible doit être signalé clairement. Les versions et limites documentées ne valent pas test en jeu.

**Règles métier.** `Incidents` est la source des faits, `Vengeance` possède la transition ouvert → vengé et son attribution, `Wanted` calcule le niveau de recherche, `Reputation` calcule les récompenses et le classement. Éviter quatre copies concurrentes de compteurs. Récompenser uniquement des incidents effectivement clôturés une fois. L'attribution en groupe et les conflits de revendication doivent être décidés avant le codage de leur résolution.

**Interface.** Les quatre vues utilisent les mêmes règles et données. La carte est dans la fiche recherchée ; les plaques de nom sont gérées séparément et seulement si le client l'autorise. Les textes, chiffres et contrôles restent dynamiques ; les images de maquette ne deviennent pas un écran figé en production. Les assets doivent être adaptés au client avec leurs licences, puis comparés aux références visuelles.

**Synchronisation.** Des identifiants d'incident et de vengeance stables relient les modules. Le protocole est versionné, borné et validé avant fusion ; une copie reçue n'accorde pas de réputation supplémentaire. L'identité des membres et la guilde doivent être vérifiées. Ne jamais exécuter une chaîne reçue comme du Lua.

**Discord.** Le relais reste indépendant et facultatif. Proposition de réalisation : Python, avec dépendances minimales. La méthode d'export depuis Forever n'est pas encore validée ; `export_reader.py` est un point d'extension prévu, pas la promesse d'une lecture en direct. Ne jamais exécuter un fichier SavedVariables pour le lire : parseur limité ou format d'export explicitement validé. Le webhook et l'état local restent dans la configuration personnelle du relais, exclus de l'archive et des sources. Un relais de guilde est privilégié ; la reprise après réponse réseau incertaine reste à concevoir, sans promettre un envoi exactement une fois.

## Ordre de chargement et livraison

Ordre de principe du TOC : `Init` → `Config` → adaptateurs `Forever` → `Data` → règles `Features` → `Sync` → `Export` → thème/widgets/vues `UI` → `Core`. Les fichiers déclarent leurs fonctions lors du chargement ; l'abonnement aux événements et l'accès à la sauvegarde se font après l'initialisation de l'addon. Les textures et polices sont des ressources, pas des entrées Lua.

Le TOC déclarera une seule sauvegarde, `SyndicatRougeDB`, dont le schéma devra être versionné et compartimenté par guilde/royaume et personnage lorsque nécessaire. L'interface numérique du TOC sera fixée après vérification du client ; ne pas créer aujourd'hui un manifeste présenté comme compatible en jeu.

Archive prévue : `dist/SyndicatRouge-forever-<version>.zip`, contenant `SyndicatRouge/` à sa racine. Le relais sera livré séparément. Les maquettes, données fictives, journaux personnels et secrets sont exclus des paquets WoW.

## Découpage des prochaines étapes

1. Stabiliser les états de données, le barème et les règles d'attribution, puis développer incidents et réputation avec fixtures hors jeu.
2. Construire la fenêtre et les quatre vues avec une source fictive réservée au développement ; conserver l'apparence choisie.
3. Vérifier et intégrer l'observation Forever, la persistance et les plaques de nom quand un client sera disponible.
4. Développer le partage de guilde et tester deux clients, conflits et rattrapage.
5. Intégrer la sortie Discord via une méthode d'export vérifiée, puis tester sa reprise et préparer les paquets.

Les étapes décrivent les dépendances ; elles ne valident aucune fonction déjà livrée. Les preuves et l'état de chaque besoin restent dans `docs/plans/death-note/implementation-matrix.md`.
