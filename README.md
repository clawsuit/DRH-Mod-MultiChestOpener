# Multi Chest Opener

Open or abandon many chests at once from the town's inventory.

<!-- drh:show -->
Press **UNLOCK** on a chest in the town's storage and pick how many to open: from 1 to what your keys and gold allow, with the cost and any gold spend shown before you confirm. Press **ABANDON** instead and the same window discards the number you pick, with a second confirmation because it cannot be undone.

- Drag the slider or use **+** and **−** to pick the amount.
- **GAME WINDOW** hands the chest back to the game's own window, so you can buy keys with gems or see the normal reveal. In discard mode it is **ONE BY ONE**, the game's single-chest abandon prompt.
- If no key can be paid with gold and you have none, the game's own window opens directly.
- With a full weapon storage the open run stops before opening anything and leaves the chests to you.
- A gold purchase always asks for a second press.
- If the server rejects a chest, the run stops and says so.
- Chests the server is still busy with are retried once.

The loot comes as a grid with the icon of everything that dropped, its name in its rarity colour and its count. Rest the cursor on an item to read its level, type, power and modifiers. English and Spanish, switched by the **EN/ES** button and remembered by the mod.

It adds **no rows** to the game's settings menu: the language and the gold switch live in this window.
<!-- /drh:show -->

## How to use

### Open
1. Open your inventory in town and pick a chest on the **LOOT** tab.
2. Press **UNLOCK** on the chest's card.
3. Pick the amount, press **OPEN**, and press again if the run buys keys with gold.
4. The loot appears at the end as a grid of icons; more than 12 goes on another page.

The slider's maximum is what your keys and gold allow right now:

- the **keys** of that chest's kind;
- the keys you can **buy with gold**, while **PAY KEYS WITH GOLD** is on;
- and never more than the chests you own of that kind.

Small and royal item boxes have no stored keys of their own, so the mod buys their key with gold and opens them the same way. If there is nothing it can pay with, it opens the game's own window instead, where gems can be used.

### Abandon
1. Press **ABANDON** on the chest's card.
2. Pick how many to discard.
3. Press **ABANDON N CHESTS** and then **CONFIRM ABANDON N**. The second press is mandatory.

Only the town inventory's chests are affected. The dungeon summary's KEEP / DROP and UNLOCK stay native.

## Details

- Chests are handled one at a time against the server, waiting for each answer, so the inventory, keys and gold update as if you did it by hand.
- The per-chest reveal window is not shown when opening in bulk; the loot is shown at the end. Use **GAME WINDOW** for the normal reveal.
- Every visit starts at **1** chest; the amount is not remembered.
- The mod keeps only the panel language and the gold switch in `data/multi_chest_opener/settings.json`. It adds **no rows** to the game's settings menu.
- If something fails, it leaves a log in `data/multi_chest_opener/last.log`.

## Requirements

- DRH 18 and the `api` mod 1.5 or a compatible later 1.x.
- It is an `extends` mod: it uses the game's own classes, so a big DRH update may break it.
- **Full Inventory** is optional. When it is loaded, the open run lets the server decide about a full storage, as that mod shows chests past the standard limit.