#!/usr/bin/env bash

set -e

rm -f prompt.md

echo -e "<response-format>Respond with ONLY the changed files, with instructions to add or remove new ones if necessary.</response-format>\n" >> prompt.md

find . -type f | grep -v ".sh" | grep -v ".md" | grep -v ".lock" | grep -v "hardware.nix" | while read file; do
  echo "<file path=\"$file\">"
  cat "$file"
  echo "</file>"
  echo
done >> prompt.md

echo >> prompt.md
echo "<error-message>" >> prompt.md
nix flake check .# --all-systems 2>&1 &>> prompt.md || true
echo "</error-message>" >> prompt.md

echo "Done, generated prompt.md."
