# Arathi — nom de carte de démonstration

5 novembre 2026. La démo indiquait la carte inconnue. Lecture ciblée du propre rapport `SyndicatRougeDemo.lua` du client : **mapID 1417**, nom **Hautes-terres d'Arathi**, `technical=textures_loaded`, 12 tuiles, contrôle visuel du rapport encore `not_checked`. Aucune exécution du fichier de sauvegarde ni donnée de personnage copiée dans le dépôt.

Cause : la démo utilise `d’Arathi` avec U+2019, alors que le nom fourni par Forever contient l'apostrophe ASCII. `MapLocations.lua` normalise seulement les apostrophes typographiques avant comparaison du nom complet. Pas d'ID ajouté en dur, de recherche partielle ou de contournement du refus des cartes ambiguës. Aucune coordonnée inventée.

Régression : quatre contrôles supplémentaires dans `map_spec.lua` ; nom réel reproduit, coordonnées absentes, ambiguïté maintenue et autre nom non assimilé. `node tools/test-native.mjs` passé : 19 cartes et 154 autres contrôles/scénarios, soit 173, plus le parcours de livraison à deux VM. Les 72 tests moteur/transport de la tranche précédente sont inchangés.

Installation : seul `SyndicatRougeDemo/MapLocations.lua` remplacé, empreinte vérifiée ; original sous `dist/client-backups/arathi-20261105-204012`. Après `/reload`, `/srdemo` et sélection de Brisecroc, l'utilisateur confirme **« Oui, la carte s’affiche »**. Validation visuelle transmise par l'utilisateur, pas capture de l'agent. Archives déjà publiées non remplacées ; le correctif sera inclus dans le prochain paquet généré depuis les sources à jour.
