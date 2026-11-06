# Jeu de données pour deux membres — 0.5.3-dev

Scénario entièrement fictif pour WoW Forever. Le JSON de référence est [primes-partage-v1.json](../../test-data/primes-partage-v1.json). Il ne s'importe pas dans le registre réel : la commande dédiée utilise les identités publiques des deux testeurs à la place des exemples du fichier.

## Préparer

Installer le principal 0.5.3 sur les deux ordinateurs. Le compagnon de démonstration est facultatif. Tous deux connectés dans Le Syndicat Rouge, hors combat et hors instance :

1. Tous deux : `/reload`, puis `/srtest debut`. Le bandeau doit indiquer **TEST PARTAGÉ**. Le partage normal est suspendu pendant le test.
2. Attendre dix secondes pour que les deux addons se reconnaissent. **Un seul** joueur, appelé **A** ci-dessous, saisit `/srtest charger`. L'autre est **B**.
3. Si l'ami n'est pas encore identifié, A utilise `/srtest charger Nom complet de B`, exactement comme son nom apparaît dans le chat. S'il y a plusieurs testeurs présents, préciser ce nom également.
4. Laisser quelques secondes pour l'échange, puis ouvrir `/sr` sur les deux clients. Les fiches commencent par **TEST**.

## Données initiales

| Recherché fictif | Race / classe / sexe / niveau | Victime | Incidents ouverts | Récompense de test | Carte |
|---|---|---|---:|---:|---|
| TEST Mornecroc | Orc guerrier, homme, 60 | A | 2 | 2 | Vallée de Strangleronce |
| TEST Sélénombre | Elfe de la nuit mage, femme, 60 | A | 1 | 1 | Vallée de Strangleronce |
| TEST Brisecroc | Nain paladin, homme, 60 | A | 1 | 1 | Hautes-terres d'Arathi |
| TEST Noctis | Humain voleur, homme, 60 | B | 1 | 1 | Hautes-terres d'Arathi |

Cinq incidents, quatre fiches. Horaires relatifs au chargement, positions explicitement fictives sur les cartes déjà vérifiées dans le client. Aucune inférence concernant une race, une classe ou un vrai meurtre. Portraits et cartes restent les ressources du client.

## Vengeances, notifications et mercis

| Qui | Commande / action | Résultat attendu |
|---|---|---|
| B | `/srtest venger mornecroc` | Deux incidents clôturés ; B gagne 2 points **de test** ; A reçoit une notification de vengeance |
| A | Onglet Notifications, sélectionner cette vengeance puis **Remercier** | Demande en attente, puis confirmation quand B la reçoit |
| B | Onglet Notifications | Merci de A visible ; le marquer lu ; aucun point supplémentaire |
| B | `/srtest venger brisecroc` | Dossier vengé ; B totalise 3 points de test ; nouvelle notification pour A |
| A | `/srtest venger noctis` | Dossier vengé ; A totalise 1 point de test ; notification pour B |
| Tous deux | Onglet Vengeurs | B : 3 points ; A : 1 point |
| Tous deux | Onglets Recherchés et Journal | Sélénombre reste à venger ; les trois autres dossiers sont archivés/vengés ; historique des cinq incidents et trois vengeances |
| B | Répéter `/srtest venger mornecroc` | Refus de doublon, aucun point ajouté |

Les commandes simulent des vengeances **uniquement dans ce mode fictif**. Elles ne prouvent ni détection de kill ni vengeance automatique. Pour essayer aussi Sélénombre, B peut saisir `/srtest venger selenombre` : B totalisera alors 4 points, contrairement au résultat du tableau ci-dessus.

## Sauvegarde et sortie

Le registre de test et ses remerciements sont sauvegardés sous une branche séparée du profil. Après `/reload`, le mode normal revient ; pour reprendre le test sauvegardé, chacun saisit `/srtest debut`, sans recharger les données.

Pour terminer, chacun saisit `/srtest fin` : le registre normal revient, les primes et points réels restent inchangés. Le mode test reprend le partage normal s'il était actif avant le test.

Pour recommencer à zéro : **les deux** font `/srtest fin`, puis `/srtest effacer`, avant de rentrer de nouveau en test. Effacer agit uniquement sur les données fictives de son personnage ; conserver le test de l'ami pourrait les resynchroniser à la prochaine entrée.

## Limites et validation

Préfixe réseau distinct `SRGuildTest1`, scope de guilde suffixé `:test-v1`, stockage `SyndicatRougeCharacterDB.guildTest` distinct. Le mode normal refuse toujours les incidents `source=demo`. Le mode test n'accepte que des incidents de démonstration et des identifiants de test pour les incidents/vengeances. Pas d'envoi Discord ni de changement de détection PvP.

Les tests entre trois VM isolées vérifient le partage A/B, les 5 incidents, les vengeances, le clic de remerciement et sa livraison, le classement 3/1, le rechargement/reprise et l'absence de mutation des registres normaux A/B et du troisième client resté hors test. Un test d'interface vérifie le bandeau, pas le rendu visuel en jeu. L'acceptation réelle de ce scénario à deux reste à effectuer.

Validation du 5 novembre 2026 : `node tools/test-native.mjs`, **198 contrôles/scénarios**, dont 37 de guilde, plus les trois parcours entre VM (noms historiques, régionaux, jeu de test isolé), passés. `node tools/export-shared-test-data.mjs` produit le JSON depuis le même constructeur Lua que la commande du jeu ; vérifie cinq incidents marqués démonstration. Le transport de test conserve les contrôles d'identité, de guilde, de verrouillage du chat, le rythme d'envoi, le découpage borné et les confirmations ; aucun accès aux valeurs protégées ajouté. Le banc de test transporte maintenant les trames comme octets hexadécimaux entre VM afin de conserver correctement les accents coupés entre deux paquets.

Installation principale locale : **33 fichiers**, sauvegarde `dist/client-backups/guild-transport-20261105-230938`, empreintes source/destination vérifiées. Archive principale `dist/SyndicatRouge-forever-0.5.3-dev.zip`, SHA256 `63401dbea215510dfe172a7c1c12ff233543206fa20848fb0e1a71c165e07733`, chaque entrée comparée à la source par le générateur PowerShell. Pas de nouvelle publication GitHub/CurseForge ; ami à mettre à jour manuellement avec ce ZIP local. Pas de modification externe de WTF et aucun envoi Discord.
