# Brainrot Trattoria

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/mr1229751/brainrot-trattoria/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/mr1229751/brainrot-trattoria/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

An original Steal-a-Brainrot-style tycoon for make.fun's roblox-brainrot-01
bounty. Absurd Italian-food brainrot characters ride a conveyor down a bright
turquoise island; you buy them onto pedestals in your base, they earn cash
every second, and you climb a ladder of rarities, mutations and rebirths while
rivals try to steal from your unlocked base and a tsunami sweeps the map every
three minutes.

## The game

- **12 original characters** — from Gnocchi Guapo (Common, $2/s) to Gorgonzola
  Galassia (Secret, $6,500,000/s) — each built from Roblox primitives with a
  floating name / rarity / $‑per‑second tag. No external models, no asset ids,
  no copied names.
- **Mutations** — Radioactive Ragu 3x (10%), 24K Dorato 8x (2%), Vuoto Astrale
  25x (0.2%), rolled at spawn with visible dressing (neon, gold foil and
  orbiting stars, void shell and trail).
- **Conveyor** — brainrots ride the belt; buy one with a prompt and it travels
  to a free pedestal in your base.
- **Bases** — 8 colour-coded 40x40 plots, 12 glowing pedestals each, a gold
  collect pad that banks your uncollected earnings, and a laser gate you lock
  for 60 seconds with the big red button or the HUD.
- **Stealing** — lift a brainrot from an unlocked rival base, carry it overhead
  under a red [STEALING!] tag at 25% reduced speed, and reach your own base to
  claim it. The owner's touch wins it straight back.
- **Tsunami** — every 180 seconds a 10-second warning banner and countdown,
  then a 60-stud wave sweeps the conveyor; anyone outside their base is swept
  to spawn and drops their loot, and the belt washes clean.
- **Rebirth** — the golden shrine sells rebirths from $25,000,000 (x8 each):
  reset cash and pedestals for a permanent +100% income, +10% WalkSpeed and
  x1.5 mutation luck per rebirth.
- **Persistence** — cash, pedestals and rebirths save to a DataStore (fully
  guarded, so Studio without API access never errors).
- **Announcements + leaderboard** — rare and mutated spawns, steals and
  rebirths get a banner on every screen, and a physical richest-tycoons board
  by the east spawn refreshes every 5 seconds.
- **Celebrations + Brainrotpedia** — confetti bursts when a brainrot lands on
  a pedestal, and a GUIDE button opens a scrolling list of all twelve
  characters, the three mutations and the rebirth terms.

## Layout

- `src/shared/` — `Roster.luau` (cast, mutations, builders, tags),
  `Config.luau` (all tuning), `PlayerData.luau` (the one place player state lives).
- `src/server/` — one system per file: `World`, `Bases`, `Conveyor`,
  `Economy`, `Stealing`, `Tsunami`, `Rebirth`, `Persistence`, `Announcements`,
  `Leaderboard`, `Showcase`
  (Studio-only photo staging), `Main` (wiring check) and `Registry` (the
  server-only wiring between the Scripts).
- `src/client/HUD.client.luau` — cash / $‑per‑second ticker, rebirth badge,
  tsunami countdown bar, Lock Base and Rebirth buttons. Top-left stays empty
  for Roblox's menu buttons.
- `main.ts` hands the game in with the kit's vendored library; `game.rbxl` is
  built with Rojo: `rojo build default.project.json -o game.rbxl`.

## Screenshots

`SHOWCASE` mode (Studio only) stages the photo scenes with the real builders:
two showcase bases full of high-rarity brainrots, a rarity parade on the
conveyor, a dummy thief mid-steal, and the tsunami on a loop — plus showcase
cash so every system can be exercised in a Play Solo test.

---

<sub>Entered on [make.fun](https://make.fun/?ref=xf80fxjd&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>

## Play it

[Brainrot Trattoria on Roblox](https://www.roblox.com/games/89625099915060) — buy brainrots from the conveyor, fill your base, lock the laser gate, steal from rivals, dodge the tsunami and rebirth for multipliers.
