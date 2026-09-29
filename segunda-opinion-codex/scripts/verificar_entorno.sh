#!/usr/bin/env bash
# Chequea que la Mac tenga lo necesario. Sale con 0 si todo está listo.
ok=0
if ! command -v codex >/dev/null 2>&1; then
  echo "FALTA: Codex CLI. Instalar con:  brew install --cask codex   (o: npm install -g @openai/codex)"
  ok=1
else
  st=$(codex login status 2>&1)
  if echo "$st" | grep -q "Logged in using ChatGPT"; then
    echo "OK: Codex con sesión de ChatGPT ($(codex --version 2>/dev/null | head -1))"
  elif echo "$st" | grep -qi "API key"; then
    echo "AVISO: Codex usa una API key (se factura aparte). Para usar la suscripción: codex logout && codex login"
  else
    echo "FALTA: iniciar sesión. Ejecutar en Terminal:  codex login   y elegir 'Sign in with ChatGPT'"
    ok=1
  fi
fi
if command -v pdftotext >/dev/null 2>&1; then echo "OK: pdftotext"
elif [ "$(uname)" = "Darwin" ]; then echo "OK: PDFs con PDFKit de macOS (sin instalar nada)"
else echo "AVISO: sin lector de PDF (instalar poppler)"; fi
exit $ok
