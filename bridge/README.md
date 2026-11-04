# Relais Discord — Le Syndicat Rouge

Relais extérieur au jeu, en Python 3.10 ou plus récent, sans dépendance Python supplémentaire. Aucun webhook, bot ou salon n'est créé par le programme. La configuration d'exemple est désactivée.

## Essayer sans Discord

Depuis la racine du dépôt :

```text
python -m bridge.syndicat_rouge preview tests/fixtures/discord-export-demo.json
```

Cette commande prépare les annonces en mémoire. Aucun envoi ni fichier de base de données. Ajouter `--output apercu.json` pour enregistrer explicitement le résultat.

L'aperçu navigateur `demo/build/discord.html` utilise les mêmes messages produits par le relais. Il propose un export fictif et des filtres de présentation, sans activer une configuration réelle.

## File persistante de démonstration

```text
python -m bridge.syndicat_rouge enqueue tests/fixtures/discord-export-demo.json --config bridge/config.example.json
python -m bridge.syndicat_rouge status
```

La base locale est `bridge/state/queue.sqlite3`, exclue de Git. Elle est liée à une seule guilde et à un seul mode : `demo` ou `live`. Un fichier plus ancien n'efface pas les faits ni les conflits déjà connus. Ne pas partager cette base entre plusieurs relais ou la copier comme donnée de l'addon.

Les annonces de recherche sont regroupées tant qu'elles ne sont pas envoyées. Les revendications de vengeance contradictoires ne sont pas annoncées comme acquises ; une annonce en attente est annulée. Une vengeance déjà publiée peut donner lieu à une correction. Aucun compteur de réputation reçu dans un fichier n'est accepté comme preuve.

Les catégories désactivées à l'import sont marquées ignorées et ne sont pas réannoncées automatiquement après activation. Les annonces déjà en attente sont à inspecter avant toute activation de l'envoi. Les corrections de messages déjà publiés ne sont pas masquées par un filtre ultérieur.

## Activation réelle — non configurée

Le code de transport est présent, mais aucun essai n'a été effectué sur un vrai salon. L'exporteur actuel produit toujours `mode: demo`, que `send` refuse. Ne pas transformer un scénario fictif en export réel en modifiant son étiquette.

Une future intégration devra produire des faits réels validés et définir la cadence d'export depuis Forever. Elle utilisera une configuration personnelle `bridge/config.local.json` avec l'identifiant de guilde réel et `enabled: true`. L'URL du webhook restera dans la variable d'environnement locale `SYNDICAT_DISCORD_WEBHOOK`, jamais dans l'addon, les exports ou le dépôt. Ne pas la publier dans le chat.

La commande d'envoi sera alors explicitement `python -m bridge.syndicat_rouge send --config bridge/config.local.json`. Elle exige mode réel, guilde concordante, activation et URL HTTPS Discord valide. Les redirections sont refusées. Les mentions automatiques sont désactivées. L'envoi confirmé enregistre l'identifiant du message Discord ; un résultat incertain n'est pas automatiquement réessayé.

## Reprise après incident

- `pending` : en attente ; `sent` : confirmation reçue ; `uncertain` : résultat à vérifier ; `failed` : rejet définitif ; `cancelled`/`skipped` : non publiable ; `held` : correction suspendue tant que l'envoi d'origine reste incertain.
- Si `uncertain` apparaît, vérifier manuellement le salon, puis utiliser `resolve IDENTIFIANT delivered --message-id IDENTIFIANT_DISCORD`, `resolve IDENTIFIANT cancel`, ou `resolve IDENTIFIANT retry`. Un ancien message devenu contesté ne peut pas être réessayé comme une victoire.
- Après un arrêt brutal, arrêter tout processus du relais puis exécuter `recover --confirm-stopped`. Les envois interrompus deviennent incertains. Ne pas utiliser cette récupération pendant qu'un envoi tourne encore.
- Une réponse 429 programme la reprise selon la réponse Discord. Aucun sommeil bloquant ni délai de quota inventé. Si un message est confirmé mais que le délai de remise à zéro du quota est inconnu, l'envoi suivant reste suspendu ; vérifier les conditions avant de lever la pause avec la récupération manuelle.
- Les commandes agissent une fois, sans surveillance permanente, tâche planifiée ni envoi automatique au démarrage.

Une perte de confirmation réseau empêche de garantir « exactement une publication » : la vérification opérateur est volontaire. Le verrou logique empêche un second envoi ou un import pendant le traitement, et persiste en cas d'arrêt brutal.

## Contrat d'export

JSON UTF-8 strict, version 1, cible `forever`, guilde, mode, incidents et revendications uniquement. Aucun code Lua n'est évalué. Limites : 1 Mio par fichier, 128 incidents/128 revendications par import, 5000 faits cumulés par file. Horodatages entiers entre 1970 et fin 2099 ; les noms et identifiants sont bornés. L'appartenance à la guilde et la preuve des combats devront être établies par l'adaptateur du client, pas par un simple fichier JSON.

## Tests et régénération

```text
node tools/export-discord-fixture.mjs
python tools/generate-discord-preview.py
python -m unittest discover -s tests/bridge -v
node tools/test-lua.mjs
```

Les transports des tests sont factices. Aucun appel au réseau Discord. Les fichiers de simulation restent dans `tests/fixtures/` et `demo/assets/`, hors de l'addon distribué.

Références primaires : [webhooks Discord](https://docs.discord.com/developers/resources/webhook), [limites de débit](https://docs.discord.com/developers/topics/rate-limits).
