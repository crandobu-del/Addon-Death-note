# Contrôle des cartes de zones Forever

Mise à jour du 5 novembre : le fichier propre `SyndicatRougeDemo.lua` est maintenant présent dans les SavedVariables du compte et a été lu de façon ciblée pour Arathi : mapID 1417, `Hautes-terres d'Arathi`, 12 tuiles chargées, `visual=not_checked`. La différence d'apostrophe avec le nom de démonstration a été corrigée ; l'utilisateur confirme ensuite l'affichage de cette carte dans le dossier. Cela ne transforme pas les autres cartes en validations visuelles. [Détail du correctif](arathi-map-fix.md). Les difficultés d'enregistrement ci-dessous décrivent les contrôles précédents.

## Bilan transmis par l'utilisateur

Après exécution du contrôle dans le jeu : **50 cartes, 50 fonds chargés, 0 anomalie, 0 en attente**. Ce sont les compteurs relevés par l'utilisateur, pas un rapport lu automatiquement ni une capture effectuée par l'agent. Le contrôle technique de chargement est donc positif pour les 50 zones détectées. Les identifiants individuels, racines, build du rapport et éventuelles limites de découverte n'ont pas été reçus ; ne pas étendre ce résultat à des racines non détectées.

Le contrôle visuel exhaustif n'est pas établi par ces compteurs. Strangleronce a une capture utilisateur positive ; aucune validation visuelle individuelle des 49 autres cartes n'a été reçue. Le fichier SavedVariables du nouveau rapport reste introuvable après le premier `/reload`, ce qui laisse la conservation sur disque à vérifier après redémarrage complet.

Demande explicite du 5 novembre 2026 : toutes les cartes de zones, et pas seulement les quatre dossiers de démonstration. Base des sources : commit `53222cbce60374e6367988ab41af87d2e119f826`.

## Ce qui a réellement été observé

- La capture utilisateur précédente montre correctement la Vallée de Strangleronce, son fond natif et le marqueur de l'incident fictif. Cette preuve concerne une seule carte.
- Lors de cette demande, WoW Forever est détecté ouvert. La capture automatique expire ; la nouvelle tentative au premier plan est arrêtée par une interaction utilisateur. Aucun clic dans le jeu ni lancement automatique du contrôle n'est revendiqué.
- Aucun outil Witchcraft ou autre lecture de contexte/erreurs du jeu connecté n'est disponible.
- L'utilisateur indique avoir terminé le contrôle et enregistré le rapport. La recherche du fichier SyndicatRougeDemo.lua sous l'installation WoW ne trouve toutefois aucun rapport, tandis que d'autres SavedVariables ont bien été actualisées. Les compteurs transmis ensuite sont consignés ci-dessus. La prise en compte de la nouvelle déclaration SavedVariables au redémarrage complet reste à vérifier.

## Contrôle installé dans le compagnon

`MapCatalog.lua` découvre les cartes depuis le monde par défaut et la chaîne des parents de la zone du joueur. Il descend les enfants directs et complète avec les descendants des racines. Seuls les éléments `Enum.UIMapType.Zone` sont retenus ; continents, cartes cosmiques et instances ne sont pas confondus avec les zones. Les identifiants sont dédupliqués. Les erreurs, cycles, plafonds (32 parents, 4096 nœuds) et racines sont enregistrés. Une racine absente des API publiques ne peut pas être déclarée couverte.

`MapAudit.lua` utilise exactement `SyndicatRouge.MapPreview`, c'est-à-dire le composant des dossiers. Les cartes sont affichées une par une ; le contrôle attend au moins 0,15 seconde et au maximum 3 secondes pour vérifier `IsObjectLoaded()` sur toutes les tuiles visibles. Il distingue carte absente, erreur de rendu, absence de tuiles, état inconnu et délai dépassé. Un échec ne bloque pas les suivantes.

Une galerie permet de naviguer et d'indiquer explicitement « Affichage correct » ou « Problème visuel ». Les résultats visuels restent `not_checked` tant qu'aucune personne ne les a confirmés ; un fond techniquement chargé n'est jamais converti automatiquement en réussite visuelle. L'arrêt/fermeture conserve un résultat incomplet, pas une validation globale.

La variable locale `SyndicatRougeMapAudit` est sauvegardée par SyndicatRougeDemo : version du rapport, build/interface renvoyés par GetBuildInfo, racines, noms/identifiants et résultats des cartes. Aucune identité de personnage, coordonnées, données de guilde ou information Discord n'est enregistrée. L'addon principal reste sans SavedVariables dans cette tranche. Les fichiers remplacés dans l'installation sont sauvegardés sous `dist/client-backups/map-audit-*`.

## Exécution requise dans le jeu

1. Redémarrer complètement le client après cette première installation du champ SavedVariables, puis se reconnecter. Un `/reload` seul n'a pas produit de fichier de rapport lors du premier retour utilisateur ; la cause exacte n'est pas établie.
2. `/sraudit lancer` pour le contrôle technique complet. Attendre la fin du compteur ; la galerie indique les anomalies et ce qui reste à examiner.
3. `/reload` pour écrire le rapport local. Le rapport peut alors être lu depuis le fichier SavedVariables de SyndicatRougeDemo, sans exécuter son contenu dans un outil extérieur.
4. `/sraudit` rouvre la galerie et les résultats. Utiliser Précédente/Suivante pour chaque carte, puis confirmer ou signaler son apparence. Recharger pour conserver ces décisions.

L'utilisateur a confirmé le lancement et l'enregistrement, puis transmis les compteurs du bilan ci-dessus. Le fichier détaillé reste introuvable sur le disque au moment du contrôle. Les identifiants individuels, la couverture des racines et la persistance nécessitent encore une sauvegarde exploitable.

## Tests hors jeu

`node tools/test-native.mjs` : catalogue synthétique, type de carte, dédoublonnage, racines, états pending, rendu, chargement des tuiles, validation visuelle explicite, sauvegarde séparée, arrêt, délai dépassé, poursuite après échec, erreur de rendu, erreurs API, cycle et API manquante. Ces cas sont des doubles de contrats, pas des essais sur les cartes du client.

Sources API au commit Forever `eac30af597e5aaa43a60f6675ef5fdcea100375f`, version source 1.60.1.70790 : MapDocumentation.lua, MapConstantsDocumentation.lua (`UIMapType.Zone=3`) et SimpleRegionAPIDocumentation.lua (`IsObjectLoaded()->bool`). Les API de cadre et de police sont celles des modules déjà corrigés pour le client. Le rapport conservera séparément le build réellement exécuté.
