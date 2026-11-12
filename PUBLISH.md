# Publicar Multi Chest Opener

Esta carpeta es el repositorio del mod tal como lo espera el índice de DRH:
`mod.json`, `src/`, `README.md`, `LICENSE` y `.github/workflows/release.yml`.
El zip `multi_chest_opener-0.5.0.zip` ya está hecho con el contenido y el formato que usa el launcher
(plano: `mod.json`, `src/...`, `LICENSE`, `README.md`), y `index-entry.json` es la entrada del índice.

## Antes de publicar, cambia el nombre si hace falta

El repositorio de GitHub **tiene que llamarse** `DRH-Mod-MultiChestOpener`. El workflow y el índice lo exigen.

## Camino A: con Git instalado (el que usa el launcher)

1. Sube esta carpeta a GitHub como `ClawSuit/DRH-Mod-MultiChestOpener`.
2. Etiqueta la versión: `git tag v0.5.0` y `git push origin v0.5.0`.
   El workflow `Release` compila el zip y deja un borrador de release con el zip y su entrada ya generada.
3. Publica el borrador en GitHub.
4. Ejecuta, desde la carpeta del repositorio:

   ```
   "C:\Users\iClaw\AppData\Local\DRH Launcher\DRH-Launcher.exe" --pack-mod "C:\Users\iClaw\Documents\DRH-Mod-MultiChestOpener" "C:\Users\iClaw\Documents\DrhRelease"
   ```

   Eso comprueba el mod y escribe `multi_chest_opener-0.5.0.zip` + `multi_chest_opener-0.5.0.json`
   (el que hay que enviar, con el `sha256` real del zip del release).
5. Envía la entrada:

   ```
   "C:\Users\iClaw\AppData\Local\DRH Launcher\DRH-Launcher.exe" --submit-mod "C:\Users\iClaw\Documents\DRH-Mod-MultiChestOpener"
   ```

   Abre el navegador para crear el fork la primera vez y luego la página de comparación: un clic y el PR queda abierto.

## Camino B: sin Git (todo desde el navegador)

1. En GitHub crea el repositorio `DRH-Mod-MultiChestOpener`.
2. Súbele `mod.json`, `src/`, `README.md` y `LICENSE` (el botón *Upload files* acepta carpetas).
   No subas `.github/` si no vas a usar el workflow: al crear el release con etiqueta se dispararía y
   competiría con el que subas a mano.
3. En *Releases → Draft a new release*: etiqueta `v0.5.0`, y adjunta `multi_chest_opener-0.5.0.zip`.
   La URL del asset quedará así:
   `https://github.com/ClawSuit/DRH-Mod-MultiChestOpener/releases/download/v0.5.0/multi_chest_opener-0.5.0.zip`
4. Haz fork de `Tutez64/DRH-Mods-Index` y añade el archivo `mods/multi_chest_opener/0.5.0.json`
   con el contenido de `index-entry.json`. Abre el PR; el CI del índice descarga el zip y comprueba
   `size` y `sha256`.

## Si el zip cambia

`index-entry.json` guarda el `size` y el `sha256` del zip de esta carpeta. Si el release lo genera el
workflow (o si vuelves a empaquetar), vuelve a sacar la entrada con `--pack-mod`: la que él escribe es
la que el CI del índice compara.