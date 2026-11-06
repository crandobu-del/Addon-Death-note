# Chasse de guilde : gank répété, présence et accès

Demande utilisateur du 6 novembre 2026. Implémentation **0.6.0-dev** et tests hors jeu livrés : [comportement précis, limites et procédure](../../testing/guild-hunt-060.md). L'installation/publication et les essais client doivent être distingués des tests VM. Le choix automatique uniquement pour les faits PvP et les vengeances reste applicable.

## REQ-023 — Catégorie de prime renforcée pour gank répété

Créer une catégorie distincte **Gank répété** lorsqu'un même ennemi tue à répétition un même membre de la guilde. Compter des incidents distincts confirmés, sur les identités complètes ennemi/victime ; le nombre total de victimes de la guilde ne suffit pas à déclencher cette catégorie.

La catégorie apparaît dans le dossier, la liste et le filtre des recherchés, avec la récompense de réputation renforcée et la règle déclenchée. Conserver la charte existante, sans nouveau portrait généré. Le calcul doit être déterministe sur le registre partagé, indépendant de l'ordre d'arrivée des incidents et sans double comptage après rattrapage.

**Choix confirmé par l'utilisateur :** « Toutes les 3 morts en moins de 1h, récompense doublée », puis confirmation explicite du cumul : **×4 à 6 morts, ×8 à 9 morts**. Pour une même paire ennemi/victime dans une fenêtre de moins de 3 600 secondes, le multiplicateur par palier est `2 ^ floor(nombreDeMorts / 3)` : 0–2 morts ×1, 3–5 ×2, 6–8 ×4, 9–11 ×8. Ne pas confondre le multiplicateur et le montant de réputation de base. Exactement une heure ne satisfait pas « moins d'une heure ».

Les incidents retransmis ne sont pas de nouvelles morts et une même série ne redéclenche pas le même palier à chaque recalcul. Implémentation : pic historique parmi les incidents ouverts de la même victime, conservé jusqu'à clôture ; chaque revendication calcule son ensemble d'incidents référencés, séparément par victime. Pas de réécriture des récompenses historiques ni d'addition de victimes distinctes pour atteindre un palier.

Le bonus concerne la récompense en réputation ; pas d'or, pas de débit chez la victime. Le calcul affiché et le montant crédité à la clôture doivent utiliser la même règle versionnée. Les points historiques ne sont pas réécrits lors d'un changement de barème. Éviter un bonus doublé pour un même incident si plusieurs victimes déclenchent la catégorie ou si un événement est retransmis. Le périmètre du bonus et sa durée feront partie du plan d'implémentation avec le seuil choisi ; pas d'expiration implicite des primes réelles.

Critères de vérification : même paire répétée ; plusieurs victimes sans répétition d'une paire ; limites exactes de fenêtre ; doublon et conflit ; réception désordonnée ; incidents déjà vengés ; bonus crédité une fois ; test fictif isolé du réel. La disponibilité réelle de la collecte automatique reste une dépendance.

## REQ-024 — Alerte de guilde lorsqu'un recherché est repéré dans une zone

Lorsqu'un membre observe réellement un joueur recherché à prime ouverte et peut en vérifier l'identité publique exacte, transmettre un signal de présence à la guilde. L'alerte nomme le recherché, le membre qui l'a repéré, la zone et l'heure ; elle concerne une observation dans la même zone, pas une distance en mètres ni une position exacte garantie. Une prime clôturée n'est pas une raison d'alerter.

Le signal est diffusé aux membres de la guilde, y compris ceux dans d'autres zones ; « même zone » décrit le contexte de l'observateur et de la cible. Ne pas filtrer la réception aux seuls membres déjà dans cette zone. Ne pas présenter la dernière zone d'un incident ancien comme une observation actuelle, ni prétendre que l'addon peut lister tous les ennemis invisibles/lointains de la zone.

Une alerte logique doit être dédupliquée quand plusieurs membres voient le même ennemi. Proposition technique à préciser : clé guilde/identité/zone, observation récente, délai de répétition borné et coordonné entre émetteurs. Le simple masquage local d'une alerte ne doit pas masquer les notifications de vengeance ni supprimer le signal reçu.

**Choix confirmé par l'utilisateur : chat de guilde et notification dans l'addon.** Le message de chat doit être visible aussi par les membres sans l'addon ; la notification dédiée concerne les membres équipés. Un seul observateur publie le message de chat d'une alerte dédupliquée : les clients récepteurs ne le répètent pas chacun dans le chat de guilde. Aucun message extérieur n'est envoyé pour cette spécification. Vérifier le contrat et les restrictions Forever de l'envoi de chat avant d'annoncer un envoi automatique possible ; ne pas afficher l'acceptation locale comme une confirmation de réception par tous.

Messages reçus : expéditeur membre vérifié, contexte de guilde courant, identité de cible complète, zone/temps valides et données bornées. Rejeter noms protégés, homonymes, observations périmées, autre guilde et événements de démonstration. Une observation ne prouve ni meurtre ni vengeance et ne rapporte aucun point. Prévoir limites de débit, changement de zone, furtivité/disparition, réutilisation de plaque et reconnexion. Les observations de test restent dans le canal de test explicite.

Critères de vérification : alerte à un membre dans une autre zone ; deux observateurs/une alerte ; cible non recherchée ; prime vengée ; donnée protégée ; observation ancienne ; même nom court/deux identités ; changement de zone ; spam/rejeu ; client sans addon si chat choisi. Essai à deux vrais membres nécessaire.

## REQ-025 — Utilisation réservée aux membres du Syndicat Rouge

Étendre le contrôle existant du partage de guilde à l'utilisation de l'addon : interface, bouton de minicarte, marqueurs, collecte, émissions de présence, commandes de simulation et accès aux données du registre. Seul un personnage dont l'appartenance au **Syndicat Rouge** est vérifiée par les API publiques doit pouvoir les utiliser.

États : **autorisé**, **vérification en attente**, **hors guilde/autre guilde**. Une donnée de guilde temporairement indisponible ou protégée n'est pas une appartenance confirmée et ne justifie pas non plus l'effacement des données. Afficher un message d'accès clair au lieu du registre tant que le contrôle n'est pas positif. Vérifier au chargement, à la connexion et lors d'un changement de guilde ; après départ de guilde, arrêter les émissions en attente, masquer les marqueurs et fermer l'interface sensible. Une réintégration vérifiée rétablit les fonctions selon les préférences sauvegardées.

Conserver les sauvegardes sans les divulguer ni les transférer à une autre guilde ; pas d'effacement automatique du dossier WTF. Le mode démonstration ne doit pas servir à contourner l'accès dans le client distribué. Un diagnostic minimal d'état peut expliquer le refus sans afficher le registre ou les identités conservées. Cette restriction est appliquée par l'addon distribué : elle ne constitue pas une authentification sur serveur contre une copie de code modifiée.

Critères de vérification : membre au chargement ; sans guilde ; autre guilde ; API absente/erreur/valeur protégée ; récupération après attente ; départ pendant une session et pendant une émission ; retour dans la guilde ; ancien cache intact ; aucune commande/demo/marqueur ne contourne le refus. Les tests moteur isolés restent indépendants d'une session de guilde réelle.

## Mise en œuvre et dépendances

1. Définir l'accès central et ses tests de cycle de vie ; réutiliser GuildContext sans multiplier les règles d'appartenance.
2. Terminer le diagnostic du récapitulatif et prouver la collecte réelle avant d'en déduire du gank.
3. Implémenter le barème confirmé (paliers de 3 morts en moins d'une heure, ×2/×4/×8) dans les vues et la résolution des vengeances avec les mêmes tests de convergence ; préciser les règles de conservation du bonus avant le code de crédit.
4. Ajouter l'observation de présence et son transport distinct des faits de combat ; vérifier l'envoi au chat de guilde et la notification addon, puis l'essai réel à deux.
5. Revoir le rendu dans la charte acceptée, empaqueter et publier une mise à jour importante sur CurseForge après vérifications. Ne pas republier une archive inchangée pour ce seul ajout au cahier des charges.
