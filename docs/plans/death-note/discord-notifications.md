# Notifications Discord — Le Syndicat Rouge

## Besoin

Notifier le Discord de la guilde lors d'événements du registre. Fonction optionnelle ; catégories configurables. Aucun salon, webhook ou bot n'a été créé et aucun message n'a été envoyé.

## Présentation proposée

- Nouveau recherché : ennemi, victime, zone, date/heure et récompense en réputation.
- Vengeance accomplie : vengeur, ennemi, victimes vengées et réputation attribuée.
- Hausse de prime : regrouper les mises à jour proches pour éviter le bruit.
- Classement : récapitulatif à la demande ou cadence à choisir ; aucune automatisation planifiée maintenant.
- Identité d'expéditeur proposée : Le Syndicat Rouge — Death Note.
- Réglages : notifications désactivées par défaut, catégories et salon, mentions désactivées par défaut. Ne pas confondre publication dans un salon et notification personnelle garantie à tous les membres.

## Architecture à étudier

Discord propose des webhooks entrants capables de publier dans un salon sans nécessiter un compte bot. Référence consultée le 4 novembre 2026 : https://docs.discord.com/developers/resources/webhook.
Prévoir un relais extérieur au jeu entre les données accessibles de l'addon et Discord. Aucun accès HTTP arbitraire depuis un addon Forever n'a été établi. La méthode d'export, les conditions d'écriture et la latence restent à vérifier ; ne pas promettre le temps réel. Une option fondée uniquement sur les SavedVariables implique d'attendre leur écriture par le client, et ne constitue pas à elle seule un flux en direct.
Un seul relais configuré pour la guilde est une première piste. Les déconnexions, l'absence de ce relais et les envois dont la réponse réseau a été perdue doivent être traités explicitement.

## Confidentialité et fiabilité

Conserver le secret webhook dans la configuration du relais, pas dans un addon distribué ni dans sa base partagée. Ne pas demander à l'utilisateur de publier le secret dans le chat. Identifier chaque événement, dédupliquer les copies reçues de plusieurs membres, conserver l'état des envois, respecter les limites Discord et ne pas retraiter indéfiniment les erreurs. Désactiver les mentions automatiques via allowed_mentions, sauf choix explicite ultérieur.
Tests futurs : catégorie désactivée, événement dupliqué, relais indisponible, réponse incertaine après envoi, délai d'export et reprise après redémarrage. Aucun test d'intégration effectué.
