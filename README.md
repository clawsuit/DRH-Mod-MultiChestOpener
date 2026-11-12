# Multi Chest Opener

Open many chests at once from the town's inventory.

<!-- drh:show -->
Press UNLOCK on a chest in the town's storage and pick how many to open: from 1 to what your keys and gold allow, with the cost shown before spending. Chests open one after the other, and the loot comes as a grid with the icon of everything that dropped, its name in its rarity colour and its count. Rest the cursor on an item to read its level, type, power and modifiers. Small and royal item boxes are supported too, bought with gold. English and Spanish, with an EN/ES button.
<!-- /drh:show -->

## How to use

1. Open your inventory in town and pick a chest on the **LOOT** tab.
2. Press **UNLOCK** on the chest's card.
3. The mod's window opens: the chest's name, how many you have, your keys and gold, the slider with the amount to open, the cost, and the gold switch.
4. Pick the amount and press **OPEN**.

The slider's maximum is what your keys and gold allow right now:

- the **keys** of that chest's kind;
- the keys you can **buy with gold**, while **PAY KEYS WITH GOLD** is on;
- and never more than the chests you own of that kind.

Small and royal item boxes have no keys of their own, so the mod buys their key with gold and opens them the same way.

While it runs, the window shows the progress (chest 5 of 12) and a bar. At the end it shows the **LOOT** as a grid of icons; more than 12 goes on another page with the arrows. **ENTER** opens the amount picked and **ESC** closes the window.

## Language

English by default. The **EN / ES** button in the top-left corner switches the window's texts; the choice is kept in `settings.json`.

*(Español: el mod está en inglés y español; el botón EN/ES de la esquina cambia los textos y se recuerda.)*

## Details

- Chests are opened one at a time against the server, waiting for each answer, so the inventory, keys and gold update as if you opened them by hand.
- The per-chest reveal window is not shown: that is why 50 take seconds. The loot is shown at the end, with its icons.
- The mod remembers the last amount and the gold switch, in `data/multi_chest_opener/settings.json`.
- Only the town inventory's chests are affected. The dungeon summary's (KEEP / UNLOCK at the end of a run) stay as they are.
- If something fails, it leaves a log in `data/multi_chest_opener/last.log`.

## Requirements

- DRH 17 and the `api` mod 1.2.
- It is an `extends` mod: it uses the game's own classes, so a big DRH update may break it.