#!/usr/bin/env bash
# Uso: preguntar_chatgpt.sh --prompt ARCHIVO --out ARCHIVO [--doc TXT]... [--web] [--timeout SEG]
# Envía el prompt (y los documentos) a ChatGPT vía Codex CLI con la suscripción del usuario.
# Pensado para correr en segundo plano: al terminar crea ARCHIVO.done con el estado.
set -uo pipefail
PROMPT=""; OUT=""; WEB=0; TIMEOUT=900; DOCS=()
while [ $# -gt 0 ]; do case "$1" in
  --prompt) PROMPT="$2"; shift 2;; --out) OUT="$2"; shift 2;; --doc) DOCS+=("$2"); shift 2;;
  --web) WEB=1; shift;; --timeout) TIMEOUT="$2"; shift 2;; *) echo "arg desconocido: $1"; exit 2;; esac; done
[ -f "$PROMPT" ] && [ -n "$OUT" ] || { echo "faltan --prompt o --out"; exit 2; }
MODEL="${SEGUNDA_OPINION_MODELO:-gpt-6-astra}"
LOG="$OUT.log"; DONE="$OUT.done"; rm -f "$OUT" "$DONE"; : > "$LOG"
IN=$(mktemp); WD=$(mktemp -d)
cat "$PROMPT" > "$IN"
for d in ${DOCS[@]+"${DOCS[@]}"}; do
  printf '\n\n<<<DOCUMENTO: %s>>>\n' "$(basename "$d")" >> "$IN"; cat "$d" >> "$IN"; printf '\n<<<FIN DEL DOCUMENTO>>>\n' >> "$IN"
done
BASE=(exec --skip-git-repo-check --ephemeral --sandbox read-only --color never -C "$WD" -o "$OUT")
[ $WEB -eq 1 ] && BASE+=(-c 'web_search="live"')

correr() { # $@ = args extra; respeta TIMEOUT sin depender de `timeout` (no existe en macOS)
  codex "${BASE[@]}" "$@" - < "$IN" >> "$LOG" 2>&1 & local pid=$! t=0
  while kill -0 $pid 2>/dev/null; do
    sleep 5; t=$((t+5))
    if [ $t -ge "$TIMEOUT" ]; then kill $pid 2>/dev/null; sleep 2; kill -9 $pid 2>/dev/null; return 124; fi
  done
  wait $pid
}

inicio=$(date +%s); nota=""
correr -m "$MODEL"; rc=$?
if [ $rc -ne 0 ] && [ $rc -ne 124 ] && grep -qiE "model|not (found|supported|available)" "$LOG"; then
  nota="el modelo $MODEL no estuvo disponible; se usó el modelo por defecto de Codex"
  echo "--- reintento sin -m ---" >> "$LOG"; correr; rc=$?
fi
usado=$(grep -m1 -iE "^model:" "$LOG" | sed 's/^[Mm]odel: *//')
seg=$(( $(date +%s) - inicio ))
if [ $rc -eq 124 ]; then estado="TIMEOUT tras ${seg}s"
elif [ $rc -ne 0 ]; then estado="ERROR rc=$rc: $(grep -iE "error|limit|rate|usage" "$LOG" | tail -3 | tr '\n' ' ')"
elif [ ! -s "$OUT" ]; then estado="ERROR: respuesta vacía"
else estado="OK"; fi
printf 'estado: %s\nmodelo: %s\nsegundos: %s\nnota: %s\n' "$estado" "${usado:-no informado}" "$seg" "${nota:-}" > "$DONE"
rm -rf "$IN" "$WD"
