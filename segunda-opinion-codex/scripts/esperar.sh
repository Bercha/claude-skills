#!/usr/bin/env bash
# Uso: esperar.sh ARCHIVO_OUT [MAX_SEG=540]
# Bloquea sin gastar tokens hasta que exista ARCHIVO_OUT.done. Si vence MAX_SEG, imprime PENDIENTE (volver a llamar).
f="$1.done"; max="${2:-540}"; t=0
while [ ! -f "$f" ]; do sleep 5; t=$((t+5)); [ $t -ge "$max" ] && { echo "PENDIENTE tras ${t}s"; exit 3; }; done
cat "$f"
