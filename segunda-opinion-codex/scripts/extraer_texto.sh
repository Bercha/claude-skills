#!/usr/bin/env bash
# Uso: extraer_texto.sh DIR_SALIDA archivo1 [archivo2 ...]
# Convierte PDF, DOCX, DOC, RTF, ODT, TXT y MD a .txt con marcas de página cuando existen.
# Imprime una línea por archivo: RUTA_TXT | líneas | aviso
set -uo pipefail
out="$1"; shift; mkdir -p "$out"

pdf_mac() { # PDFKit, viene con macOS
osascript -l JavaScript - "$1" <<'JXA'
ObjC.import("PDFKit");
function run(argv) {
  var doc = $.PDFDocument.alloc.initWithURL($.NSURL.fileURLWithPath(argv[0]));
  if (doc.isNil()) return "__ERROR__";
  var out = [];
  for (var i = 0; i < doc.pageCount; i++) {
    var s = doc.pageAtIndex(i).string;
    out.push("=== Página " + (i + 1) + " ===\n" + (s.isNil() ? "" : s.js));
  }
  return out.join("\n");
}
JXA
}

docx_py() { python3 - "$1" <<'PY'
import sys, zipfile, re, html
z = zipfile.ZipFile(sys.argv[1]); x = z.read("word/document.xml").decode("utf8")
x = re.sub(r"<w:tab/>", "\t", x); x = re.sub(r"</w:p>", "\n", x)
print(html.unescape(re.sub(r"<[^>]+>", "", x)))
PY
}

for f in "$@"; do
  [ -f "$f" ] || { echo "$f | 0 | NO EXISTE"; continue; }
  base=$(basename "$f"); dst="$out/${base}.txt"; ext=$(echo "${f##*.}" | tr 'A-Z' 'a-z'); aviso=""
  case "$ext" in
    pdf)
      if command -v pdftotext >/dev/null 2>&1; then
        pdftotext -layout "$f" - | awk 'BEGIN{p=1; print "=== Página 1 ==="} { n=split($0,a,"\f"); if(n<=1){ if(pend){print "=== Página " p " ==="; pend=0} print $0; next } for(i=1;i<=n;i++){ if(i>1){p++; pend=1} if(a[i]!=""){ if(pend){print "=== Página " p " ==="; pend=0} print a[i] } } }' > "$dst"
      elif [ "$(uname)" = "Darwin" ]; then pdf_mac "$f" > "$dst"
      else echo "$f | 0 | SIN LECTOR PDF"; continue; fi
      grep -q "__ERROR__" "$dst" && { echo "$f | 0 | PDF ILEGIBLE"; continue; }
      chars=$(grep -v "^=== Página" "$dst" | tr -d '[:space:]' | wc -c)
      pages=$(grep -c "^=== Página" "$dst")
      [ "$pages" -gt 0 ] && [ $((chars / pages)) -lt 200 ] && aviso="POSIBLE ESCANEADO: poco texto por página, revisar";;
    docx) if command -v textutil >/dev/null 2>&1; then textutil -convert txt -stdout "$f" > "$dst"; else docx_py "$f" > "$dst"; fi;;
    doc|rtf|odt|html|htm) if command -v textutil >/dev/null 2>&1; then textutil -convert txt -stdout "$f" > "$dst"; else echo "$f | 0 | FORMATO NO SOPORTADO AQUÍ"; continue; fi;;
    txt|md) cp "$f" "$dst";;
    *) echo "$f | 0 | FORMATO NO SOPORTADO"; continue;;
  esac
  echo "$dst | $(wc -l < "$dst" | tr -d ' ') líneas | ${aviso:-ok}"
done
