# Death Note - Guild Ledger

An early guild PvP incident ledger developed for **Le Syndicat Rouge** on **World of Warcraft: Forever**. The in-game interface is currently in French.

## Current alpha

- Parchment-style interface with Wanted, Avengers, Journal and Notifications tabs.
- Client-provided zone maps and race/sex/class icons when the relevant information is known.
- Per-character persistence for the local ledger, notification states and window preferences.
- Experimental guild synchronization with explicit activation, catch-up requests, duplicate protection and delivery acknowledgements.
- Symbolic reputation calculated from recorded vengeance claims, with conflicting claims held pending.

**Important:** this is a development alpha. Automatic killer identification and vengeance detection are not connected yet. A new installation opens an empty ledger. The two-player live synchronization test is still pending; automated tests use injected records and APIs. Installing this version will not automatically create a bounty when you die.

The current guild adapter accepts members of **Le Syndicat Rouge** only. This is not yet a general-purpose addon for every guild.

## Install and open

Install the `SyndicatRouge` folder into `World of Warcraft/_forever_/Interface/AddOns/`. The TOC must be directly inside that folder. Enable the addon on the character screen, then use `/sr` or `/syndicat`. Use `/reload` after an update.

Both guild members need the same version. Each uses `/srsync activer`, then one uses `/srsync test`. The receiver should see a received-test message and the sender should see an acknowledgement. Repeat in the other direction. This test does not create an incident or award points.

Use `/srsync` for status, `/srsync actualiser` to request catch-up, `/srsync reprendre` to retry initialization, and `/srsync arreter` to stop sharing. `/srsave` prepares a local checkpoint; the game writes saved variables during reload, logout or normal shutdown.

## Restrictions and data

Only ordinary GUILD addon messages are used. Secret values and masked identities are refused. No protected combat log access, combat automation or bypass of client restrictions is attempted. If Forever restricts outgoing addon messages, sharing pauses.

The wire format shares validated incidents and vengeance claims with guild members. Window preferences and personal read/thank states stay local. This is a member-attested ledger, not server-certified proof of a kill. The current session limit is 128 incidents and 128 claims; historical membership handling and transmitted thanks are unfinished. Discord delivery and wanted nameplate markers are not included in this version.

The packaged parchment artwork was generated for this project. Character icons and maps come from the installed game client and are not redistributed in the archive. The Handlee font is distributed under SIL OFL 1.1; addon code is MIT licensed.

Source and issue reports: https://github.com/crandobu-del/Addon-Death-note
