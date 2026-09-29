# segunda-opinion v2 (Codex CLI · macOS)

Basado en el skill [segunda-opinion](../segunda-opinion) de Osvaldo Quintero (licencia MIT, ver LICENSE). Esta versión reemplaza el manejo de la app de ChatGPT por Codex CLI y suma un modo relevo para documentos pesados.

## Instalación (una sola vez, en Terminal)

1. Instalar Codex:  `brew install --cask codex`   (o `npm install -g @openai/codex`)
2. Iniciar sesión con la cuenta de ChatGPT:  `codex login`  → elegir "Sign in with ChatGPT".
3. Copiar esta carpeta a `~/.claude/skills/segunda-opinion/`
4. Dar permiso de ejecución:  `chmod +x ~/.claude/skills/segunda-opinion/scripts/*.sh`
5. Probar:  `~/.claude/skills/segunda-opinion/scripts/verificar_entorno.sh`

## Uso (en Claude Code: pestaña Code de Claude desktop, o `claude` en Terminal)

    /segunda-opinion ¿pregunta?
    /segunda-opinion relevo: revisá la cláusula de responsabilidad de ~/Documents/MSA.pdf y el anexo ~/Documents/SOW.docx

## Notas

- En ChatGPT Plus, Astra está disponible en Codex, no en el chat clásico. El skill usa `gpt-6-astra`; si tu plan no lo tiene, cae al modelo por defecto de Codex y lo informa. Para otro modelo: `export SEGUNDA_OPINION_MODELO=...`
- El uso consume la cuota de Codex de tu plan. Documentos muy largos pueden agotarla antes que el chat.
- PDFs escaneados sin texto no sirven: hay que pasarlos por OCR antes.

## Si algo falla al instalar

- **`codex` no aparece en Claude Code aunque en Terminal sí.** Claude Code corre los comandos con bash, que no lee `~/.zshrc`. Agregá la misma ruta a `~/.bash_profile`, por ejemplo: `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile`, y abrí una sesión nueva.
- **Homebrew no anda** (Macs con Apple Silicon que heredaron un Homebrew de Intel en `/usr/local`, o versiones nuevas de macOS que no reconoce). Se puede instalar Codex sin Homebrew ni npm: bajar `codex-aarch64-apple-darwin.tar.gz` de https://github.com/openai/codex/releases, descomprimirlo, verificar la firma con `codesign -dvv` (debe decir *Developer ID Application: OpenAI OpCo, LLC*), moverlo a `~/.local/bin/codex` y darle `chmod +x`.
