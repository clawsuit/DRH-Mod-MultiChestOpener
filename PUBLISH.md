# Publicar Multi Chest Opener

Repositorio: <https://github.com/clawsuit/DRH-Mod-MultiChestOpener>
Versión preparada: **0.7.0**

## Antes de etiquetar

- `mod.json` con `version: "0.7.0"`, `api: "1.5"` y `drh: "18"`.
- `README.md` con la zona `<!-- drh:show -->` actualizada.
- `LICENSE` presente.
- `--check-mod` correcto.
- Compilación en staging con `mode: compiled`.
- `backup/` no forma parte del mod; no se versiona.

## Con Git

Desde esta carpeta:

```powershell
git add -A
git commit -m "Multi Chest Opener 0.7.0: bulk abandon, no settings rows, no MAX"
git tag v0.7.0
git push origin main
git push origin v0.7.0
```

El workflow `Release` compila el zip y deja un **draft release** con el zip y la entrada del índice.

## Publicar el release

Abre el borrador en GitHub y pulsa **Publish release**. No subas un zip hecho a mano: la entrada lleva
el `size` y el `sha256` del zip que generó el workflow.

## Enviar al índice

```powershell
& "C:\Users\iClaw\AppData\Local\DRH Launcher\DRH-Launcher.exe" --submit-mod "C:\Users\iClaw\Documents\DRH-Mod-MultiChestOpener"
```

Abre el navegador para crear el fork la primera vez y luego la página del PR. El CI del índice descarga
el zip del release y comprueba `size`, `sha256` y la entrada.

## Validación local opcional

```powershell
$env:PATH = "C:\Program Files\Git\cmd;" + $env:PATH
& "C:\Users\iClaw\AppData\Local\DRH Launcher\DRH-Launcher.exe" --pack-mod `
  "C:\Users\iClaw\Documents\DRH-Mod-MultiChestOpener" `
  "C:\Users\iClaw\Documents\DrhRelease"
```

Genera `multi_chest_opener-0.7.0.zip` y `multi_chest_opener-0.7.0.json`. El zip que se publica es el
del workflow; el JSON del workflow es el que se envía al índice.