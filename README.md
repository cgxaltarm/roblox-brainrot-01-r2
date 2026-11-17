# Brainrot Night Market — roblox-brainrot-01 (round 2 rebuild)

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/cgxaltarm/roblox-brainrot-01-r2/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/cgxaltarm/roblox-brainrot-01-r2/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

<sub>Entered on [make.fun](https://make.fun/?ref=witty-badger-10&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>

A 3D Roblox brainrot game set in a real night market plaza. Players buy
absurd Indonesian-food brainrots off a red-carpet conveyor, carry them to
their own kiosk base, and earn money every second — money that piles up
at the base until they walk to the green COLLECT pad to take it. Rarer
characters, mutations, a pity timer, a collection Index, named-character
rebirths and a gear shop give the hunt a long tail, while thieves (other
players, and a roaming thief NPC during Rush Hour) keep every trip home
tense.

Round 2 is a rebuild of the round-1 game: every character now has its
own silhouette (a signature prop built from Parts, defined as data in
`BrainrotData`), the world is a real night market (dark sky, string
lights, warm lamps, neon sign, cobble ground), bases are kiosks with
walls, an awning, an owner board and a visible laser gate, conveyor
labels are three separate lines on a dark backplate, and the shop cards
are dark with bold white text and gold prices.

## How to play

1. Spawn at the south gate with $100. The tutorial shows the first three steps.
2. Walk to the conveyor on the north edge: 5 brainrots on show, a new one arrives every 6 seconds.
3. Click a brainrot to buy it, carry it to one of your 8 base slots, click a pad to place it. It starts earning its $/s immediately — into a pile at your base.
4. Walk to the green COLLECT pad in front of your base to take the pile.
5. Buy rarer characters, fill your slots, then rebirth: each level needs cash plus two NAMED characters (shown with checkmarks in the Rebirth panel) for +50% income, +1 base slot and +10 s lock.
6. Spend cash at the Coins Shop: Slap ($500) knocks a thief down, Speed Coil ($750) makes you 50% faster for 30 s, Trap ($1,000) freezes a thief for 7 s.
7. Defend your base: other players can steal from an unlocked base, anyone can tag the thief to make them drop the catch, and a $1,500 base lock stops stealing for 20 seconds (+10 s per rebirth).
8. Watch the pity board: an Epic is guaranteed every ~3 minutes, a Legendary every ~8 minutes. Every 4 minutes an event fires: Rush Hour (2x conveyor speed + a thief NPC raids a base), Festival (2x income for 45 seconds), or Golden Hour (every spawn is Golden).

## The cast

20 original Indonesian-food characters across 7 rarities (Common, Rare,
Epic, Legendary, Mythic, Secret, Brainrot God), with Golden / Rainbow /
Diamond mutations that multiply income. Every character model carries a
billboard with its name, rarity colour and $/s on three separate lines.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/shared/` holds the catalogue (`BrainrotData`, with each character's prop parts), tuning (`Config`) and money formatting (`Format`).
- `src/server/` holds the server systems: economy and the collect pile, conveyor and pity timer, character models, the world builder, bases, stealing and the thief NPC, events, gear and saving. The server owns all state.
- `src/client/` holds the HUD, shop (conveyor cards, gear, rebirth, Index) and effects. The client only renders.
- `screenshots/` holds 3–4 captures of the game running in Roblox Studio; the first by name is the game's thumbnail on Roblox.
- `PLAY.json` names the published public place on Roblox.

## Build it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Play it on Roblox: see `PLAY.json` for the public place link.
